//
//  VideoPlayerView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/9.
//

import AVFoundation
import AVKit
import SwiftUI

struct VideoPlayerView: View {
    let video: MediaItemViewModel
    @Binding var isPresented: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
//            VideoPlayer(player: AVPlayer(url: video.phAsset))
//                .ignoresSafeArea()

            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
            }
        }.background(.black)
    }
}
