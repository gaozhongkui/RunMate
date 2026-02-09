//
//  VideoPlayerView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/9.
//

import AVFoundation
import AVKit
import Photos
import SwiftUI

struct VideoPlayerView: View {
    let video: MediaItemViewModel
    @Binding var isPresented: Bool
    
    @State private var player: AVPlayer?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear { player.play() }
            }
            
            if isLoading {
                ProgressView("正在加载视频...")
                    .tint(.white)
                    .foregroundColor(.white)
            }

            // 关闭按钮
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .onAppear {
            loadVideoAsset()
        }
    }

    private func loadVideoAsset() {
        let asset = video.phAsset
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true // 允许从 iCloud 下载
        options.deliveryMode = .highQualityFormat

        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            DispatchQueue.main.async {
                if let urlAsset = avAsset as? AVURLAsset {
                    // 成功获取 URL，创建播放器
                    self.player = AVPlayer(url: urlAsset.url)
                    self.isLoading = false
                }
            }
        }
    }
}
