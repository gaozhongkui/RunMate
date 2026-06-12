//
//  EncryptedImageCardView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/6.
//

import SwiftUI

// 让 UIImage 可作为 sheet(item:) 的 item，直接携带数据避免 if-let 捕獲時序問題
private struct IdentifiableImage: Identifiable {
    let id = UUID()
    let uiImage: UIImage
}

struct EncryptedImageCardView: View {
    let image: EncryptedImage
    @ObservedObject var storageManager: StorageManager
    @State private var showDecryptSheet = false
    @State private var decryptPassword = ""
    @State private var pendingImage: UIImage?       // 臨時存儲解密結果
    @State private var viewableImage: IdentifiableImage?  // 驅動圖片查看 sheet
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isDecrypting = false

    var body: some View {
        HStack(spacing: 15) {
            // 加密狀態圖標，不顯示原圖縮略圖
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 60, height: 60)
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(image.fileName)
                    .font(AppTheme.Fonts.headline())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                Text(image.createdDate, style: .date)
                    .font(AppTheme.Fonts.caption())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text("\(image.encryptedData.count / 1024) KB")
                    .font(AppTheme.Fonts.caption2())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()

            // 解密按鈕
            Button {
                showDecryptSheet = true
            } label: {
                Image(systemName: "lock.open.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                    .padding(10)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Circle())
            }

            // 刪除按鈕
            Button {
                withAnimation {
                    storageManager.deleteImage(image)
                }
            } label: {
                Image(systemName: "trash.fill")
                    .font(.title3)
                    .foregroundColor(.red)
                    .padding(10)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .appCardStyle(cornerRadius: AppTheme.Radius.sm + 5)
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showDecryptSheet, onDismiss: {
            guard let img = pendingImage else { return }
            pendingImage = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                viewableImage = IdentifiableImage(uiImage: img)
            }
        }) {
            DecryptPasswordSheet(
                password: $decryptPassword,
                isDecrypting: $isDecrypting,
                onConfirm: decryptImage
            )
        }
        .sheet(item: $viewableImage) { item in
            ImageViewerSheet(image: item.uiImage)
        }
        .alert("common_notice", isPresented: $showAlert) {
            Button("common_ok", role: .cancel) {}
        } message: {
            Text(LocalizedStringKey(alertMessage))
        }
    }

    private func decryptImage() {
        guard !decryptPassword.isEmpty else {
            alertMessage = "vault_error_no_password"
            showAlert = true
            return
        }

        isDecrypting = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let decryptedData = try EncryptionManager.shared.decryptImage(
                    image.encryptedData,
                    password: decryptPassword
                )

                guard let uiImage = UIImage(data: decryptedData) else {
                    throw NSError(domain: "ImageError", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Failed to render image"])
                }

                DispatchQueue.main.async {
                    self.pendingImage = uiImage
                    isDecrypting = false
                    decryptPassword = ""
                    showDecryptSheet = false
                }
            } catch {
                DispatchQueue.main.async {
                    isDecrypting = false
                    alertMessage = "vault_decrypt_hint" // 密碼錯誤提示
                    showAlert = true
                }
            }
        }
    }
}
