//
//  HomeView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import SwiftUI

import DotLottie

struct HomeView: View {
    let namespace: Namespace.ID

    var body: some View {
        VStack {
            Color.white.ignoresSafeArea()

            DotLottieAnimation(
                fileName: "loading",
                config: AnimationConfig(autoplay: true, loop: true)
            )
            .view() 
            .frame(width: 200, height: 200)
        }
    }
}
