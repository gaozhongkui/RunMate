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

                // Gradient + content block
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
                    // Gradient background extends upward from the top of this VStack by half a screen
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0),
                                Color.black.opacity(0.85),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: geo.size.height * 2)  // Extend upward to cover twice the height
                        .offset(y: -geo.size.height)  // Offset upward so the gradient fades in from above
                    }
                )
            }
            .ignoresSafeArea(edges: .bottom)

            // Close button
            closeButton()
        }
        .toast(item: $toast)
        .onAppear {
            image = store.loadImage(for: record)
        }
    }

    @ViewBuilder
    private func detailContent() -> some View {
        GeometryReader { geo in
            Group {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
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
            .frame(width: geo.size.width, height: geo.size.height)
        }
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
            Button {
                dismiss()
            } label: {
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 22).stroke(
                                Color.white.opacity(0.2),
                                lineWidth: 1
                            )
                        )
                    Image(systemName: "trash")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            Button(action: {
                guard let temp = self.image else {
                    return
                }

                ImageDownloader().saveToPhotoLibrary(image: temp) { success in
                    toast =
                        success
                        ? ToastModel(
                            message: "Saved to Photos",
                            icon: "checkmark.circle.fill"
                        )
                        : ToastModel(
                            message: "Save failed",
                            icon: "xmark.circle.fill"
                        )
                }
            }) {
                Text("Download")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hex: "#C260F5"), Color(hex: "#6034E4"),
                            ],
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
