import CryptoKit
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct ImageEncryptionView: View {
    var namespace: Namespace.ID
    
    @Environment(\.dismiss) var dismiss
    @State private var storageManager = StorageManager()
    @State private var selectedItem: PhotosPickerItem?
    @State private var showPasswordInput = false
    @State private var password = ""
    @State private var selectedImageData: Data?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isEncrypting = false
    
    var body: some View {
        ZStack {
            AppTheme.Colors.pageGradient
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 顶部说明卡片
                    InfoCardView()
                        .padding(.horizontal)
                    
                    // 选择图片按钮
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                                .font(.title2)
                            Text("Select Image to Encrypt")
                                .font(AppTheme.Fonts.subheadline(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .appPrimaryButtonStyle()
                        .shadow(color: AppTheme.Colors.accentStart.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    
                    // 加密图片列表
                    if storageManager.encryptedImages.isEmpty {
                        EmptyStateView(
                            icon: "photo.on.rectangle.angled",
                            title: "No encrypted images yet",
                            subtitle: "Tap the button above to select an image to encrypt"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(storageManager.encryptedImages) { image in
                                    EncryptedImageCardView(image: image, storageManager: $storageManager)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
        }
        .navigationTitle("Image Vault")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPasswordInput) {
            PasswordInputSheet(
                password: $password,
                isEncrypting: $isEncrypting,
                onConfirm: encryptSelectedImage
            )
        }
        .alert("Notice", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                    showPasswordInput = true
                }
            }
        }
    }

    
    private func encryptSelectedImage() {
        guard let imageData = selectedImageData, !password.isEmpty else {
            alertMessage = "Please enter a password"
            showAlert = true
            return
        }
        
        isEncrypting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let encryptedData = try EncryptionManager.shared.encryptImage(imageData, password: password)
                
                // 创建缩略图
                let thumbnail = createThumbnail(from: imageData)
                
                let encryptedImage = EncryptedImage(
                    fileName: "IMG_\(Date().timeIntervalSince1970)",
                    encryptedData: encryptedData,
                    thumbnailData: thumbnail
                )
                
                DispatchQueue.main.async {
                    storageManager.saveImage(encryptedImage)
                    isEncrypting = false
                    showPasswordInput = false
                    password = ""
                    selectedImageData = nil
                    alertMessage = "Image encrypted successfully!"
                    showAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    isEncrypting = false
                    alertMessage = "Encryption failed: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func createThumbnail(from imageData: Data) -> Data? {
        guard let uiImage = UIImage(data: imageData) else { return nil }
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        uiImage.draw(in: CGRect(origin: .zero, size: size))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return thumbnail?.jpegData(compressionQuality: 0.5)
    }
}
