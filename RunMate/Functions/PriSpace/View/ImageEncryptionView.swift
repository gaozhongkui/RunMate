import CryptoKit
import Photos
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
    @State private var selectedAssetIdentifier: String?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isEncrypting = false
    @State private var showDeleteOriginalAlert = false
    
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
                                .font(AppTheme.Fonts.subheadline(.semibold)).foregroundColor(.white)
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
        .navigationTitle("Image Safe")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
        .alert("Delete Original Photo?", isPresented: $showDeleteOriginalAlert) {
            Button("Delete", role: .destructive) {
                deleteOriginalFromLibrary()
            }
            Button("Keep", role: .cancel) {
                selectedImageData = nil
                selectedItem = nil
                selectedAssetIdentifier = nil
            }
        } message: {
            Text("Remove the original photo from your photo library? It will only be viewable inside this app.")
        }
        .onChange(of: selectedItem) { _, newItem in
            selectedAssetIdentifier = newItem?.itemIdentifier
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
                let encryptedImage = EncryptedImage(
                    fileName: "IMG_\(Date().timeIntervalSince1970)",
                    encryptedData: encryptedData
                )
                
                DispatchQueue.main.async {
                    storageManager.saveImage(encryptedImage)
                    isEncrypting = false
                    showPasswordInput = false
                    password = ""
                    showDeleteOriginalAlert = true
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
    
    private func deleteOriginalFromLibrary() {
        guard let identifier = selectedAssetIdentifier else {
            selectedImageData = nil
            selectedItem = nil
            selectedAssetIdentifier = nil
            return
        }
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.deleteAssets(assets)
                    }) { _, _ in
                        DispatchQueue.main.async {
                            selectedImageData = nil
                            selectedItem = nil
                            selectedAssetIdentifier = nil
                        }
                    }
                } else {
                    alertMessage = "Photo library access denied. Original photo was not deleted."
                    showAlert = true
                    selectedImageData = nil
                    selectedItem = nil
                    selectedAssetIdentifier = nil
                }
            }
        }
    }
}
