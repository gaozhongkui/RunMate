//
//  ImageDetailsView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/3.
//

import Kingfisher
import SwiftUI
import Zoomable

struct MeDetailsView: View {
    let record: AIGeneratedImage
    let store: AIImageStore
    
    @Environment(\.dismiss) var dismiss

    @State private var toast: ToastModel? = nil

    @State private var image: UIImage? = nil

    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            detailContent().ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 渐变 + 内容整体
                VStack(spacing: 0) {
                    Text(record.prompt)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)

                    actionButton()
                        .padding(.bottom, 40)
                }
                .background(
                    // 渐变背景从这个 VStack 顶部向上延伸半屏
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [Color.black.opacity(0), Color.black.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: geo.size.height * 2) // 向上延伸覆盖两倍高度
                        .offset(y: -geo.size.height)        // 向上偏移，使渐变从上方淡入
                    }
                )
            }
            .ignoresSafeArea(edges: .bottom)

            // 关闭按钮
            closeButton()
        }
        .toast(item: $toast)
        .onAppear {
            image = store.loadImage(for: record)
        }
    }

    @ViewBuilder
    private func detailContent() -> some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .zoomable()
            } else {
                LinearGradient(
                    colors: [Color(hex: "1E1535"), Color(hex: "2A1B50")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.2))
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func getPlaceholderView() -> some View {
        ZStack {
            Image("img_loading").resizable()
            ProgressView().tint(.white)
        }
    }

    private func closeButton() -> some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
        }
    }

    private func actionButton() -> some View {
        HStack(spacing: 12) {
            Button(action: {
                store.delete(record)
                dismiss()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    Image(systemName: "trash")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            Button(action: {
                ImageDownloader().downloadAndSaveImage(from: record.fileName) { success in
                    toast = success
                        ? ToastModel(message: "Saved to Photos", icon: "checkmark.circle.fill")
                        : ToastModel(message: "Save failed", icon: "xmark.circle.fill")
                }
            }) {
                Text("Download")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [Color(hex: "#C260F5"), Color(hex: "#6034E4")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .cornerRadius(22)
                    )
            }
        }
        .padding(.horizontal, 30)
    }
}
