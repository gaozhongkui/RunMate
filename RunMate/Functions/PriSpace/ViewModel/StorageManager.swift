//
//  StorageManager.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/6.
//

import SwiftUI

@Observable
@MainActor
class StorageManager {
    var encryptedImages: [EncryptedImage] = []
    
    private let storageFileName = "encryptedImages.json"
    private var documentsPath: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport
    }
    
    init() {
        loadImages()
    }
    
    func saveImage(_ image: EncryptedImage) {
        encryptedImages.insert(image, at: 0)
        saveToFile()
    }
    
    func deleteImage(_ image: EncryptedImage) {
        encryptedImages.removeAll { $0.id == image.id }
        saveToFile()
    }
    
    private func saveToFile() {
        let fileURL = documentsPath.appendingPathComponent(storageFileName)
        do {
            let data = try JSONEncoder().encode(encryptedImages)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("保存失败: \(error)")
        }
    }
    
    private func loadImages() {
        let fileURL = documentsPath.appendingPathComponent(storageFileName)
        guard let data = try? Data(contentsOf: fileURL) else { return }
        encryptedImages = (try? JSONDecoder().decode([EncryptedImage].self, from: data)) ?? []
    }
}
