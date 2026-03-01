//
//  ImageResultView.swift
//  RunMate
//

import Photos
import SwiftUI
import UIKit
import Zoomable

struct ImageResultView: View {
    var generatedImage: UIImage?
    var backAction: () -> Void
    var confirmAction: () -> Void

    @State private var saveState: SaveState = .idle
    @State private var showToast = false

    enum SaveState {
        case idle
        case saving
        case success
        case failed(String)
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.pageGradient
                .ignoresSafeArea()

            contentLayout()

            VStack {
                headerView()
                Spacer()
                bottomLayout()
            }

            // 成功/失败 Toast
            if showToast {
                toastView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
    }

    // MARK: - Header

    private func headerView() -> some View {
        HStack {
            Button(action: { backAction() }) {
                Image(systemName: "chevron.left")
                    .font(AppTheme.Fonts.headline())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.textPrimary.opacity(0.1))
                    .clipShape(Circle())
            }
            Spacer()
            Text("Art Ready")
                .font(AppTheme.Fonts.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)
            Spacer()
            // 分享按钮
            Button(action: { shareImage() }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: - Content

    private func contentLayout() -> some View {
        VStack {
            Spacer()
            if let uiImage = generatedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(AppTheme.Radius.xl)
                    .shadow(color: AppTheme.Colors.accentEnd.opacity(0.3), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 20)
                    .zoomable()
            } else {
                Image("ai_loading")
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(AppTheme.Radius.xl)
                    .padding(.horizontal, 20)
            }
            Spacer()
        }
        .padding(.vertical, 80)
    }

    // MARK: - Bottom

    private func bottomLayout() -> some View {
        VStack(spacing: 0) {
            Button(action: { saveToPhotoLibrary() }) {
                HStack(spacing: 10) {
                    if case .saving = saveState {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else if case .success = saveState {
                        Image(systemName: "checkmark.circle.fill")
                    } else {
                        Image(systemName: "arrow.down.to.line.circle.fill")
                    }

                    Text(buttonLabel)
                }
                .font(AppTheme.Fonts.headline())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(buttonBackground)
                .cornerRadius(AppTheme.Radius.xxl - 5)
                .shadow(color: AppTheme.Colors.accentEnd.opacity(0.5), radius: 12, y: 6)
            }
            .disabled(saveState == .saving || saveState == .success)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.8), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Toast

    private var toastView: some View {
        VStack {
            HStack(spacing: 8) {
                if case .failed = saveState {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                Text(toastMessage)
                    .font(AppTheme.Fonts.subheadline(.medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color(hex: "1E1535").opacity(0.95))
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
            )
            .padding(.top, 60)
            Spacer()
        }
    }

    // MARK: - Save Logic

    private func saveToPhotoLibrary() {
        guard let image = generatedImage else { return }

        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            performSave(image: image)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.performSave(image: image)
                    } else {
                        self.showFailure("Please allow photo access in Settings")
                    }
                }
            }
        case .denied, .restricted:
            showFailure("Please allow photo access in Settings")
        @unknown default:
            break
        }
    }

    private func performSave(image: UIImage) {
        saveState = .saving

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    saveState = .success
                    confirmAction()   // 同步保存到 AIImageStore 历史记录
                    showToastMessage()
                } else {
                    showFailure(error?.localizedDescription ?? "Save failed")
                }
            }
        }
    }

    private func showFailure(_ message: String) {
        saveState = .failed(message)
        showToastMessage()
        // 失败后允许重试
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            saveState = .idle
        }
    }

    private func showToastMessage() {
        withAnimation(.spring()) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut) {
                showToast = false
            }
        }
    }

    private func shareImage() {
        guard let image = generatedImage else { return }
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController
        {
            rootVC.present(vc, animated: true)
        }
    }

    // MARK: - Computed

    private var buttonLabel: String {
        switch saveState {
        case .idle:    return "Save to Gallery"
        case .saving:  return "Saving..."
        case .success: return "Saved!"
        case .failed:  return "Try Again"
        }
    }

    private var buttonBackground: some View {
        Group {
            switch saveState {
            case .success:
                LinearGradient(
                    colors: [Color.green.opacity(0.8), Color.teal],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            case .failed:
                LinearGradient(
                    colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            default:
                AppTheme.Colors.accentGradient
            }
        }
    }

    private var toastMessage: String {
        switch saveState {
        case .success:        return "Saved to Photos"
        case .failed(let msg): return msg
        default:              return ""
        }
    }
}

// SaveState Equatable 支持 disabled 判断
extension ImageResultView.SaveState: Equatable {
    static func == (lhs: ImageResultView.SaveState, rhs: ImageResultView.SaveState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.saving, .saving), (.success, .success): return true
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
    }
}
