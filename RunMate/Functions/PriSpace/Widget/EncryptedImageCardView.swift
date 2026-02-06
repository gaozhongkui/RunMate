//
//  EncryptedImageCardView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/6.
//

import SwiftUI

struct EncryptedImageCardView: View {
    let image: EncryptedImage
    @Binding var storageManager: StorageManager
    @State private var showDecryptSheet = false
    @State private var decryptPassword = ""
    @State private var decryptedImage: UIImage?
    @State private var showImageViewer = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isDecrypting = false
    
    var body: some View {
        HStack(spacing: 15) {
            // 缩略图或图标
            if let thumbnailData = image.thumbnailData,
               let thumbnail = UIImage(data: thumbnailData)
            {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: "photo.fill")
                    .font(.title)
                    .foregroundColor(.gray)
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(image.fileName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(image.createdDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(image.encryptedData.count / 1024) KB")
                    .font(.caption2)
                    .foregroundColor(.secondary)
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
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showDecryptSheet) {
            DecryptPasswordSheet(
                password: $decryptPassword,
                isDecrypting: $isDecrypting,
                onConfirm: decryptImage
            )
        }
        .sheet(isPresented: $showImageViewer) {
            if let decryptedImage = decryptedImage {
                ImageViewerSheet(image: decryptedImage)
            }
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func decryptImage() {
        guard !decryptPassword.isEmpty else {
            alertMessage = "请输入密码"
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
                    throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法生成图片"])
                }
                
                DispatchQueue.main.async {
                    self.decryptedImage = uiImage
                    isDecrypting = false
                    showDecryptSheet = false
                    showImageViewer = true
                    decryptPassword = ""
                }
            } catch {
                DispatchQueue.main.async {
                    isDecrypting = false
                    alertMessage = "解密失败，请检查密码是否正确"
                    showAlert = true
                }
            }
        }
    }
}
