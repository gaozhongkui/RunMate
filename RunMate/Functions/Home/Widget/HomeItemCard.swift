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
    
    // 可配置的延迟时间（秒）
    private let videoPlayDelay: TimeInterval = 1.5
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            
            VStack(alignment: .leading, spacing: 0) {
                // 媒体展示区
                ZStack {
                    // 缩略图或占位符
                    if let image = thumbnail {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(AppTheme.Colors.cardBackgroundAlt)
                            .overlay(ProgressView().tint(.white.opacity(0.5)))
                    }
                    
                    // 视频播放器叠加在缩略图上方
                    if isVideo, shouldShowVideo, let player = player {
                        InnerVideoPlayerView(player: player)
                            .transition(.opacity)
                    }
                }
                .frame(width: geometry.size.width, height: item.viewHeight)
                .clipped()
                
                // 底部信息栏
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
            // 先加载缩略图
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
        print("📍 Visibility changed: \(isVisible), player: \(player != nil), title: \(item.title)")
        
        if isVisible {
            // 变为可见
            if player != nil {
                // 已有播放器，恢复播放
                print("▶️ Resuming existing player for: \(item.title)")
                withAnimation(.easeIn(duration: 0.3)) {
                    shouldShowVideo = true
                }
                player?.play()
            } else if item.phAsset?.mediaType == .video {
                // 需要加载视频
                print("🔄 Starting delayed video load for: \(item.title)")
                startDelayedVideoLoad()
            }
        } else {
            // 变为不可见
            print("⏸️ Stopping player for: \(item.title)")
            cancelAllTasks()
            stopAndReleasePlayer()
            shouldShowVideo = false
        }
    }
    
    private func startDelayedVideoLoad() {
        // 取消之前的任务
        cancelAllTasks()
        
        // 延迟加载视频
        videoDelayTask = Task {
            // 先确保缩略图已加载
            await loadThumbnailIfNeeded()
            
            // 等待指定时间
            try? await Task.sleep(nanoseconds: UInt64(videoPlayDelay * 1_000_000_000))
            
            // 检查任务是否被取消
            guard !Task.isCancelled, isVisible else {
                print("⚠️ Video load task cancelled for: \(item.title)")
                return
            }
            
            // 开始加载视频
            print("🎬 Delayed video load executing for: \(item.title)")
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
    
    // MARK: - 媒体加载
    
    func loadMedia() async {
        print("🔍 loadMedia called for: \(item.title)")
        print("   - phAsset exists: \(item.phAsset != nil)")
        print("   - phAsset type: \(item.phAsset?.mediaType.rawValue ?? -1)")
        
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
        print("🖼️ Loading thumbnail for: \(item.title)")
        await loadThumbnail(phAsset: phAsset)
    }
    
    func loadVideo(phAsset: PHAsset) async {
        print("🎬 loadVideo started for: \(item.title)")
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        
        let fetchedItem: AVPlayerItem? = await withCheckedContinuation { continuation in
            var isResumed = false
            PHImageManager.default().requestPlayerItem(forVideo: phAsset, options: options) { playerItem, _ in
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
            
            // 先显示视频播放器，再开始播放
            withAnimation(.easeIn(duration: 0.3)) {
                shouldShowVideo = true
            }
            
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
        await MainActor.run {
            self.thumbnail = image
            print("✅ Thumbnail loaded for: \(item.title)")
        }
    }
}
