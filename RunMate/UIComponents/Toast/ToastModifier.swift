//
//  ToastModifier.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/4.
//

import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastModel?
    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if let toast = toast {
                        toastView(toast).transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(), value: toast)
            )
            .onChange(of: toast) { _, newValue in
                if newValue != nil {
                    showToast()
                }
            }
    }

    @ViewBuilder
    private func toastView(_ toast: ToastModel) -> some View {
        HStack(spacing: 15) {
            if let icon = toast.icon {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(toast.message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 28)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        }
        .background {
            Capsule()
                .fill(Color.black.opacity(0.4))
        }
        .overlay {
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .clear, .white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.top, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func showToast() {
        // 取消之前的定时器
        workItem?.cancel()

        let task = DispatchWorkItem {
            withAnimation {
                toast = nil
            }
        }
        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + (toast?.duration ?? 2.0), execute: task)
    }
}
