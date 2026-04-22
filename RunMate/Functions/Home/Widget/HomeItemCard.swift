//
//  HomeItemCard.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/5.
//

import AVKit
import Photos
import SwiftUI

struct HomeItemCard: View {
    let item: HomeItem
    
    @State private var thumbnail: UIImage?
    @State private var isVideo: Bool = false
    @State private var player: AVPlayer?
    @State private var isVisible: Bool = false
    @State private var playerItemObserver: Any?
    @State private var loadTask: Task<Void, Never>?
    @State private var videoDelayTask: Task<Void, Never>?
    @State private var shouldShowVideo: Bool = false
    
    // Configurable delay duration (seconds)
    private let videoPlayDelay: TimeInterval = 1.5
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            
            VStack(alignment: .leading, spacing: 0) {
                // Media display area
                ZStack {
                    // Thumbnail or placeholder
                    if let image = thumbnail {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(AppTheme.Colors.cardBackgroundAlt)
                            .overlay(ProgressView().tint(.white.opacity(0.5)))
                    }
                    
                    // Video player overlaid on top of the thumbnail
                    if isVideo, shouldShowVideo, let player = player {
                        InnerVideoPlayerView(player: player)
                            .transition(.opacity)
                    }
                }
                .frame(width: geometry.size.width, height: item.viewHeight)
                .clipped()
                
                // Bottom info bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.title)
                            .font(AppTheme.Fonts.body(.semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(1)
                        if isVideo {
                            Image(systemName: "video.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    Text(item.size)
                        .font(AppTheme.Fonts.subheadline(.medium))
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.cardBackground)
            }
            .frame(width: geometry.size.width)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.Radius.md)
            .onChange(of: frame) { _, newFrame in
                checkVisibility(frame: newFrame)
            }
        }
        .frame(height: item.viewHeight + 60)
        .onAppear {
            configureAudioSession()
            // Load thumbnail first
            Task { await loadThumbnailIfNeeded() }
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? audioSession.setActive(true)
    }
    
    // MARK: - Visibility Detection

    private func checkVisibility(frame: CGRect) {
        let screenBounds = UIScreen.main.bounds

        // Calculate visible ratio
        let visibleHeight = min(frame.maxY, screenBounds.height) - max(frame.minY, 0)
        let visibilityRatio = visibleHeight / frame.height

        let shouldBeVisible = visibilityRatio > 0.5 // visible when more than 50%
        
        if shouldBeVisible != isVisible {
            isVisible = shouldBeVisible
            handleVisibilityChange()
        }
    }
    
    private func handleVisibilityChange() {
        if isVisible {
            if player != nil {
                withAnimation(.easeIn(duration: 0.3)) {
                    shouldShowVideo = true
                }
                player?.play()
            } else if item.phAsset?.mediaType == .video {
                startDelayedVideoLoad()
            }
        } else {
            cancelAllTasks()
            stopAndReleasePlayer()
            shouldShowVideo = false
        }
    }
    
    private func startDelayedVideoLoad() {
        // Cancel previous tasks
        cancelAllTasks()

        // Load video with delay
        videoDelayTask = Task {
            await loadThumbnailIfNeeded()
            try? await Task.sleep(nanoseconds: UInt64(videoPlayDelay * 1_000_000_000))
            guard !Task.isCancelled, isVisible else { return }
            await loadMedia()
        }
    }
    
    private func cancelAllTasks() {
        loadTask?.cancel()
        videoDelayTask?.cancel()
        loadTask = nil
        videoDelayTask = nil
    }
    
    private func stopAndReleasePlayer() {
        player?.pause()
        player = nil
        if let observer = playerItemObserver {
            NotificationCenter.default.removeObserver(observer)
            playerItemObserver = nil
        }
    }
    
    private func cleanup() {
        cancelAllTasks()
        stopAndReleasePlayer()
        shouldShowVideo = false
    }
    
    // MARK: - Media Loading
    
    func loadMedia() async {
        guard let phAsset = item.phAsset else {
            await MainActor.run { self.isVideo = false }
            return
        }
        guard phAsset.mediaType == .video else {
            await MainActor.run { self.isVideo = false }
            return
        }
        await MainActor.run { self.isVideo = true }
        await loadVideo(phAsset: phAsset)
    }

    private func loadThumbnailIfNeeded() async {
        guard thumbnail == nil, let phAsset = item.phAsset else { return }
        await loadThumbnail(phAsset: phAsset)
    }

    func loadVideo(phAsset: PHAsset) async {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic

        let fetchedItem: AVPlayerItem? = await withCheckedContinuation { continuation in
            var isResumed = false
            PHImageManager.default().requestPlayerItem(forVideo: phAsset, options: options) { playerItem, _ in
                if !isResumed {
                    isResumed = true
                    continuation.resume(returning: playerItem)
                }
            }
        }

        guard let playerItem = fetchedItem else { return }

        await MainActor.run {
            guard isVisible else { return }

            let avPlayer = AVPlayer(playerItem: playerItem)
            avPlayer.isMuted = true

            playerItemObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak avPlayer] _ in
                avPlayer?.seek(to: .zero)
                avPlayer?.play()
            }

            self.player = avPlayer
            withAnimation(.easeIn(duration: 0.3)) {
                shouldShowVideo = true
            }
            avPlayer.play()
        }
    }

    func loadThumbnail(phAsset: PHAsset) async {
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: 300 * scale, height: item.viewHeight * scale)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        let image: UIImage? = await withCheckedContinuation { continuation in
            var isResumed = false
            PHImageManager.default().requestImage(for: phAsset, targetSize: targetSize, contentMode: .aspectFill, options: options) { result, _ in
                if !isResumed {
                    isResumed = true
                    continuation.resume(returning: result)
                }
            }
        }
        await MainActor.run { self.thumbnail = image }
    }
}
