//
//  AIImageStore.swift
//  RunMate
//

import SwiftUI
import UIKit

@Observable
class AIImageStore {
    static let shared = AIImageStore()

    private(set) var records: [AIGeneratedImage] = []

    private let metadataKey = "AIGeneratedImageMetadata"

    private var imagesDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AIGeneratedImages", isDirectory: true)
    }

    private init() {
        ensureDirectory()
        loadMetadata()
    }

    // MARK: - Public

    func save(image: UIImage, prompt: String, styleTitle: String) {
        let id = UUID()
        let fileName = "\(id.uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)

        if let data = image.jpegData(compressionQuality: 0.85) {
            try? data.write(to: fileURL)
        }

        let record = AIGeneratedImage(
            id: id,
            prompt: prompt,
            styleTitle: styleTitle,
            createdAt: Date(),
            fileName: fileName
        )

        records.insert(record, at: 0)
        saveMetadata()
    }

    func loadImage(for record: AIGeneratedImage) -> UIImage? {
        let fileURL = imagesDirectory.appendingPathComponent(record.fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }

    func delete(_ record: AIGeneratedImage) {
        let fileURL = imagesDirectory.appendingPathComponent(record.fileName)
        try? FileManager.default.removeItem(at: fileURL)
        records.removeAll { $0.id == record.id }
        saveMetadata()
    }

    // MARK: - Private

    private func ensureDirectory() {
        try? FileManager.default.createDirectory(
            at: imagesDirectory,
            withIntermediateDirectories: true
        )
    }

    private func saveMetadata() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: metadataKey)
        }
    }

    private func loadMetadata() {
        guard
            let data = UserDefaults.standard.data(forKey: metadataKey),
            let saved = try? JSONDecoder().decode([AIGeneratedImage].self, from: data)
        else { return }
        records = saved
    }
}
