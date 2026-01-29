//
//  AIImageProcessingView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

struct AIImageProcessingView: View {
    var backAction: () -> Void
    var processingAction: () -> Void

    @State private var progress: CGFloat = 0.0

    var body: some View {
        VStack {
            headerView()
            contentView().frame(maxHeight: .infinity)
        }.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    progress = 1.0
                }
            }
        }
    }

    private func headerView() -> some View {
        ZStack {
            Text("Generating Art")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            HStack {
                Button(action: { backAction() }) {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .foregroundColor(.white)
                        .padding(11)
                        .background(Color(hex: "#868095").opacity(0.2))
                        .clipShape(Circle())
                }
                .frame(width: 44, height: 44)

                Spacer()
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }

    private func contentView() -> some View {
        VStack(spacing: 20) {
            ProgressCircleView(progress: $progress).padding(.top, 120)
            Text("Creating your artwork...").font(.system(size: 20)).foregroundColor(.white.opacity(0.9)).padding(.top, 60)
        }
    }
}
