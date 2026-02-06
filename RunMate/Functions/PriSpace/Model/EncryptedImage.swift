//
//  EncryptedImage.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/6.
//
import SwiftUI

struct EncryptedImage: Identifiable, Codable {
    let id: UUID
    let fileName: String
    let encryptedData: Data
    let thumbnailData: Data?
    let createdDate: Date
    
    init(id: UUID = UUID(), fileName: String, encryptedData: Data, thumbnailData: Data? = nil) {
        self.id = id
        self.fileName = fileName
        self.encryptedData = encryptedData
        self.thumbnailData = thumbnailData
        self.createdDate = Date()
    }
}
