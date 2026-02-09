//
//  InnerVideoPlayerView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/6.
//

import AVFoundation
import AVKit
import SwiftUI


struct InnerVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.backgroundColor = .clear
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(playerLayer)
        
        // 👇 保存引用到 view 自身，而不是 coordinator
        view.playerLayer = playerLayer
        
        return view
    }
    
    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        // 👇 确保 playerLayer 的 player 是最新的
        if uiView.playerLayer?.player !== player {
            uiView.playerLayer?.player = player
        }
        
        // 👇 直接更新 frame，不需要异步
        uiView.playerLayer?.frame = uiView.bounds
    }
    
    // 👇 使用自定义 UIView 类来管理 playerLayer
    class PlayerContainerView: UIView {
        var playerLayer: AVPlayerLayer?
        
        override func layoutSubviews() {
            super.layoutSubviews()
            // 👇 在布局时自动更新 frame
            playerLayer?.frame = bounds
        }
        
        // 👇 清理资源
        deinit {
            playerLayer?.player = nil
            playerLayer?.removeFromSuperlayer()
        }
    }
}
