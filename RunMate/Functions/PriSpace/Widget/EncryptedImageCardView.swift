//
//  EncryptedImageCardView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/6.
//

import SwiftUI

// 让 UIImage 可作为 sheet(item:) 的 item，直接携带数据避免 if-let 捕获时序问题
private struct IdentifiableImage: Identifiable {
    let id = UUID()
    let uiImage: UIImage
}

struct EncryptedImageCardView: View {
    let image: EncryptedImage
    @Binding var storageManager: StorageManager
    @State private var showDecryptSheet = false
    @State private var decryptPassword = ""
    @State private var pendingImage: UIImage?       // 临时存储解密结果
    @State private var viewableImage: IdentifiableImage?  // 驱动图片查看 sheet
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isDecrypting = false

    var body: some View {
        HStack(spacing: 15) {
            // 加密状态图标，不显示原图缩略图
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

            // 解密按钮
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

            // 删除按钮
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
        // 解密密码 sheet：onDismiss 后等动画结束再展示图片 sheet，避免两个 sheet 冲突
        .sheet(isPresented: $showDecryptSheet, onDismiss: {
            guard let img = pendingImage else { return }
            pendingImage = nil
            // 等 sheet 关闭动画（~0.35s）彻底完成后再弹出图片
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
        // 使用 sheet(item:) 直接传递图片数据，不依赖额外 Bool 状态
        .sheet(item: $viewableImage) { item in
            ImageViewerSheet(image: item.uiImage)
        }
        .alert("Notice", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func decryptImage() {
        guard !decryptPassword.isEmpty else {
            alertMessage = "Please enter a password"
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
                    // 先把图片存到 pendingImage，关闭 sheet 后 onDismiss 会取走它
                    self.pendingImage = uiImage
                    isDecrypting = false
                    decryptPassword = ""
                    showDecryptSheet = false
                }
            } catch {
                DispatchQueue.main.async {
                    isDecrypting = false
                    alertMessage = "Decryption failed. Please check your password."
                    showAlert = true
                }
            }
        }
    }
}
