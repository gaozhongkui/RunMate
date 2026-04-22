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
        
        // 👇 Save reference to the view itself, not the coordinator
        view.playerLayer = playerLayer
        
        return view
    }
    
    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        // 👇 Ensure playerLayer's player is up to date
        if uiView.playerLayer?.player !== player {
            uiView.playerLayer?.player = player
        }
        
        // 👇 Update frame directly, no async needed
        uiView.playerLayer?.frame = uiView.bounds
    }
    
    // 👇 Use a custom UIView subclass to manage playerLayer
    class PlayerContainerView: UIView {
        var playerLayer: AVPlayerLayer?

        override func layoutSubviews() {
            super.layoutSubviews()
            // 👇 Automatically update frame during layout
            playerLayer?.frame = bounds
        }

        // 👇 Clean up resources
        deinit {
            playerLayer?.player = nil
            playerLayer?.removeFromSuperlayer()
        }
    }
}
