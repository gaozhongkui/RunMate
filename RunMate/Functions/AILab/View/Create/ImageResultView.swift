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

            // Success/Failure Toast
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
            Text("result_header_title")
                .font(AppTheme.Fonts.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)
            Spacer()
            // Share button
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
                        self.showFailure(NSLocalizedString("result_photo_access_denied", comment: ""))
                    }
                }
            }
        case .denied, .restricted:
            showFailure(NSLocalizedString("result_photo_access_denied", comment: ""))
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
                    confirmAction()   // Sync save to AIImageStore history
                    showToastMessage()
                } else {
                    showFailure(error?.localizedDescription ?? NSLocalizedString("common_error", comment: ""))
                }
            }
        }
    }

    private func showFailure(_ message: String) {
        saveState = .failed(message)
        showToastMessage()
        // Allow retry after failure
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
           let window = windowScene.windows.first(where: { $0.isKeyWindow }),
           let rootVC = window.rootViewController
        {
            if let popover = vc.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(
                    x: window.bounds.midX,
                    y: window.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }

            rootVC.topMostViewController.present(vc, animated: true)
        }
    }

    // MARK: - Computed

    private var buttonLabel: LocalizedStringKey {
        switch saveState {
        case .idle:    return "result_save_button"
        case .saving:  return "result_saving_status"
        case .success: return "result_saved_status"
        case .failed:  return "result_failed_status"
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
        case .success:        return NSLocalizedString("result_save_success_toast", comment: "")
        case .failed(let msg): return msg
        default:              return ""
        }
    }
}

// SaveState Equatable support for disabled judgment
extension ImageResultView.SaveState: Equatable {
    static func == (lhs: ImageResultView.SaveState, rhs: ImageResultView.SaveState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.saving, .saving), (.success, .success): return true
        case (.failed(let a), .failed(let b)): return a == b
        default: return false
        }
    }
}

private extension UIViewController {
    var topMostViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.topMostViewController
        }

        if let navigationController = self as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController
        {
            return visibleViewController.topMostViewController
        }

        if let tabBarController = self as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController
        {
            return selectedViewController.topMostViewController
        }

        return self
    }
}
