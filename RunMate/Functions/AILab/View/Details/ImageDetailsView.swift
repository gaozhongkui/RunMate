//
//  ImageDetailsView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/3.
//

import Kingfisher
import SwiftUI
import Zoomable

struct ImageDetailsView: View {
    let item: PollinationFeedItem?

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            KFImage.url(URL(string: item?.imageURL ?? ""))
                .placeholder {
                    ZStack {
                        Image("img_loading").resizable()
                        ProgressView().tint(.white)
                    }
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .zoomable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // UI 层
            VStack {
                closeButton()
                Spacer()
                actionButton()
            }
            .padding(.bottom, 20)
        }
    }

    private func closeButton() -> some View {
        HStack {
            Spacer()
            Button {
                // 2. 执行关闭动作
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle) // 加大一点方便点击
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
        }
    }

    private func actionButton() -> some View {
        HStack(spacing: 12) {
            Button(action: {
                // 下载逻辑
                print("点击下载")
            }) {
                ZStack {
                    // 背景色：可以使用半透明深色或者实色
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 60, height: 60) // 宽高一致，做成正方形
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                    Image(systemName: "arrow.down.to.line") // 下载图标
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            
            Button(action: {
                // 点击逻辑
            }) {
                Text("Generate Similar")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 60)
                    .frame(maxWidth: .infinity) // 自动撑开剩余空间
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#C260F5"), Color(hex: "#6034E4")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(22)
                    )
            }
        }
        .padding(.horizontal, 30)
    }
}
