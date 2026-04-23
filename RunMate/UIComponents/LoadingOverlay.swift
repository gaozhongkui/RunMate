//
//  LoadingOverlay.swift
//  AuraAI
//
//  A lightweight full-screen loading overlay.
//  Usage:
//    .loadingOverlay(isLoading: $isSaving, message: "Saving…")
//

import SwiftUI

// MARK: - Overlay View

struct LoadingOverlayView: View {
    let message: String

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            // Card
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.3)

                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
    }
}

// MARK: - View Modifier

private struct LoadingOverlayModifier: ViewModifier {
    let isLoading: Bool
    let message: String

    func body(content: Content) -> some View {
        ZStack {
            content
            if isLoading {
                LoadingOverlayView(message: message)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - View Extension

extension View {
    /// Displays a translucent loading overlay on top of any view.
    func loadingOverlay(isLoading: Bool, message: String = "Loading…") -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading, message: message))
    }
}
