//
//  ImageViewerSheet.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/6.
//

import Photos
import SwiftUI

struct ImageViewerSheet: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var toast: ToastModel? = nil
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1.0 {
                                    withAnimation {
                                        scale = 1.0
                                        lastScale = 1.0
                                    }
                                }
                            }
                    )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveImage()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.white)
                    }
                    .disabled(isSaving)
                }
            }
            .loadingOverlay(isLoading: isSaving, message: "Saving to Photos…")
            .toast(item: $toast)
        }
    }

    private func saveImage() {
        guard !isSaving else { return }
        isSaving = true
        ImageDownloader().saveToPhotoLibrary(image: image) { success in
            isSaving = false
            toast = success
                ? ToastModel(message: "Saved to Photos", icon: "checkmark.circle.fill")
                : ToastModel(message: "Save failed", icon: "xmark.circle.fill")
        }
    }
}
