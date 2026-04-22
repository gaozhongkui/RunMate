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
    private let documentsPath: URL = {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        if !fm.fileExists(atPath: appSupport.path) {
            try? fm.createDirectory(at: appSupport, withIntermediateDirectories: true, attributes: nil)
        }
        // 如果 Application Support 不可用，降级到 Documents
        if fm.fileExists(atPath: appSupport.path) {
            return appSupport
        }
        return fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()
    
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
            print("Save failed: \(error)")
        }
    }
    
    private func loadImages() {
        let fileURL = documentsPath.appendingPathComponent(storageFileName)
        guard let data = try? Data(contentsOf: fileURL) else { return }
        encryptedImages = (try? JSONDecoder().decode([EncryptedImage].self, from: data)) ?? []
    }
}
