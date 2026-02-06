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
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(playerLayer)
        
        context.coordinator.playerLayer = playerLayer
        
        // 立即设置初始 frame
        DispatchQueue.main.async {
            playerLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.playerLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var playerLayer: AVPlayerLayer?
    }
}
