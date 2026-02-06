//
//  HomeItemCard.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/5.
//

import Photos
import SwiftUI

struct HomeItemCard: View {
    let item: HomeItem
    @State private var thumbnail: UIImage?
    @State private var isVideo: Bool = false
    @State private var player: AVPlayer?
    @State private var isVisible: Bool = false

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    if isVideo, let player = player {
                        VideoPlayerView(player: player)
                            .frame(width: geometry.size.width, height: item.viewHeight)
                            .clipped()
                            .onAppear {
                                isVisible = true
                                player.play()
                            }
                            .onDisappear {
                                isVisible = false
                                player.pause()
                            }
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
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
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
        .task {
            await loadMedia()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    func loadMedia() async {
        guard let phAsset = item.phAsset else { return }

        let assetIsVideo = phAsset.mediaType == .video
        
        await MainActor.run {
            isVideo = assetIsVideo
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
        
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestPlayerItem(forVideo: phAsset, options: options) { playerItem, info in
                guard let playerItem = playerItem else {
                    continuation.resume()
                    return
                }
                
                Task { @MainActor in
                    let avPlayer = AVPlayer(playerItem: playerItem)
                    avPlayer.isMuted = true
                    
                    // 循环播放
                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: playerItem,
                        queue: .main
                    ) { _ in
                        avPlayer.seek(to: .zero)
                        if self.isVisible {
                            avPlayer.play()
                        }
                    }
                    
                    self.player = avPlayer
                    
                    // 等待一小段时间确保视图准备好
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                    
                    if self.isVisible {
                        avPlayer.play()
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
    func loadThumbnail(phAsset: PHAsset) async {
        let scale = UIScreen.main.scale
        let targetSize = CGSize(
            width: 200 * scale,
            height: item.viewHeight * scale
        )

        let image = await fetchImage(
            for: phAsset,
            targetSize: targetSize,
            contentMode: .aspectFill
        )

        await MainActor.run {
            thumbnail = image
        }
    }
}
