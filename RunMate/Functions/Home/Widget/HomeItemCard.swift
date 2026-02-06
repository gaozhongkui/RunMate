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

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // 媒体展示区
                ZStack {
                    if isVideo, let player = player {
                        VideoPlayerView(player: player)
                            .frame(width: geometry.size.width, height: item.viewHeight)
                            .clipped()
                    } else if let image = thumbnail {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: item.viewHeight)
                            .clipped()
                    } else {
                        // 占位图
                        Rectangle()
                            .fill(Color(hex: "#1A1629"))
                            .frame(width: geometry.size.width, height: item.viewHeight)
                            .overlay(
                                ProgressView()
                                    .tint(.white.opacity(0.5))
                            )
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
        }
        .frame(height: item.viewHeight + 60)
        // 生命周期管理
        .onAppear {
            isVisible = true
            handlePlayback()
        }
        .onDisappear {
            isVisible = false
            handlePlayback()
        }
        .task {
            await loadMedia()
        }
        // 状态变化监听：核心修复逻辑
        .onChange(of: player) {
            handlePlayback()
        }
        .onChange(of: isVisible) {
            handlePlayback()
        }
    }

    // MARK: - 播放控制逻辑

    private func handlePlayback() {
        if isVisible {
            // 只有当 player 已经初始化完成且视图可见时才播放
            if player?.rate == 0 {
                player?.play()
            }
        } else {
            player?.pause()
        }
    }

    // MARK: - 媒体加载

    func loadMedia() async {
        guard let phAsset = item.phAsset else { return }

        let assetIsVideo = phAsset.mediaType == .video
        await MainActor.run {
            self.isVideo = assetIsVideo
        }

        if assetIsVideo {
            await loadVideo(phAsset: phAsset)
        } else {
            await loadThumbnail(phAsset: phAsset)
        }
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
            let avPlayer = AVPlayer(playerItem: playerItem)
            avPlayer.isMuted = true // 自动播放通常需要静音

            // 移除旧的观察者（如果有）
            if let oldObserver = playerItemObserver {
                NotificationCenter.default.removeObserver(oldObserver)
            }

            // 设置循环播放
            playerItemObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak avPlayer] _ in
                avPlayer?.seek(to: .zero)
                avPlayer?.play()
            }

            self.player = avPlayer
        }
    }

    func loadThumbnail(phAsset: PHAsset) async {
        let scale = UIScreen.main.scale
        let targetSize = CGSize(
            width: 300 * scale,
            height: item.viewHeight * scale
        )

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        // 将 deliveryMode 设为 .highQualityFormat
        // 这样闭包通常只会被调用一次，返回最终质量的图片
        options.deliveryMode = .highQualityFormat

        let image: UIImage? = await withCheckedContinuation { continuation in
            var isResumed = false // 状态标记，确保只 resume 一次

            PHImageManager.default().requestImage(for: phAsset, targetSize: targetSize, contentMode: .aspectFill, options: options) { result, _ in
                // 如果已经 resume 过了，就不要再执行了
                if !isResumed {
                    isResumed = true
                    continuation.resume(returning: result)
                }
            }
        }

        await MainActor.run {
            self.thumbnail = image
        }
    }
}
