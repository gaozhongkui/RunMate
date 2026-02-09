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
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            
            VStack(alignment: .leading, spacing: 0) {
                // 媒体展示区
                ZStack {
                    if isVideo, let player = player {
                        InnerVideoPlayerView(player: player)
                            .frame(width: geometry.size.width, height: item.viewHeight)
                            .clipped()
                    } else if let image = thumbnail {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: item.viewHeight)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color(hex: "#1A1629"))
                            .frame(width: geometry.size.width, height: item.viewHeight)
                            .overlay(ProgressView().tint(.white.opacity(0.5)))
                    }
                }
                
                // 底部信息栏
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if isVideo {
                            Image(systemName: "video.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    Text(item.size)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .frame(width: geometry.size.width, alignment: .leading)
                .background(Color(hex: "#1A1A24"))
            }
            .background(Color(hex: "#1A1A24"))
            .cornerRadius(16)
            .onChange(of: frame) { _, newFrame in
                checkVisibility(frame: newFrame)
            }
        }
        .frame(height: item.viewHeight + 60)
        .onAppear {
            configureAudioSession()
            Task { await loadThumbnailIfNeeded() }
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    // MARK: - 可见性检测
    
    private func checkVisibility(frame: CGRect) {
        let screenBounds = UIScreen.main.bounds
        
        // 计算可见比例
        let visibleHeight = min(frame.maxY, screenBounds.height) - max(frame.minY, 0)
        let visibilityRatio = visibleHeight / frame.height
        
        let shouldBeVisible = visibilityRatio > 0.5 // 50% 以上可见
        
        if shouldBeVisible != isVisible {
            isVisible = shouldBeVisible
            handleVisibilityChange()
        }
    }
    
    private func handleVisibilityChange() {
        // 👇 在这里添加日志
        print("📍 Visibility changed: \(isVisible), player: \(player != nil), title: \(item.title)")
        
        if isVisible {
            // 变为可见
            if player != nil {
                print("▶️ Resuming existing player for: \(item.title)")
                player?.play()
            } else if item.phAsset?.mediaType == .video {
                print("🔄 Starting to load video for: \(item.title)")
                // 取消之前的加载任务
                loadTask?.cancel()
                // 开始新的加载
                loadTask = Task {
                    await loadMedia()
                }
            }
        } else {
            // 变为不可见
            print("⏸️ Stopping player for: \(item.title)")
            loadTask?.cancel()
            stopAndReleasePlayer()
        }
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
        loadTask?.cancel()
        stopAndReleasePlayer()
    }
    
    // MARK: - 媒体加载
    
    func loadMedia() async {
        print("🔍 loadMedia called for: \(item.title)")
        print("   - phAsset exists: \(item.phAsset != nil)")
        print("   - phAsset type: \(item.phAsset?.mediaType.rawValue ?? -1)") // 0=unknown, 1=image, 2=video, 3=audio
        
        guard let phAsset = item.phAsset else {
            print("❌ No phAsset for: \(item.title)")
            await MainActor.run { self.isVideo = false }
            return
        }
        
        guard phAsset.mediaType == .video else {
            print("❌ Not a video asset for: \(item.title), type: \(phAsset.mediaType.rawValue)")
            await MainActor.run { self.isVideo = false }
            return
        }
        
        print("✅ Valid video asset confirmed for: \(item.title)")
        await MainActor.run { self.isVideo = true }
        await loadVideo(phAsset: phAsset)
    }
    
    private func loadThumbnailIfNeeded() async {
        guard thumbnail == nil, let phAsset = item.phAsset else { return }
        await loadThumbnail(phAsset: phAsset)
    }
    
    func loadVideo(phAsset: PHAsset) async {
        print("🎬 loadVideo started for: \(item.title)")
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        
        let fetchedItem: AVPlayerItem? = await withCheckedContinuation { continuation in
            var isResumed = false
            PHImageManager.default().requestPlayerItem(forVideo: phAsset, options: options) { playerItem, info in
                if !isResumed {
                    isResumed = true
                    print("📦 PlayerItem fetched for: \(self.item.title), success: \(playerItem != nil)")
                    continuation.resume(returning: playerItem)
                }
            }
        }
        
        guard let playerItem = fetchedItem else {
            print("❌ Failed to fetch playerItem for: \(item.title)")
            return
        }
        
        await MainActor.run {
            guard isVisible else {
                print("⚠️ Video loaded but no longer visible: \(item.title)")
                return
            }
            
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
            avPlayer.play()
            
            print("✅ Video playing for: \(item.title)")
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
