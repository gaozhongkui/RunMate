//
//  AIGeneratedImage.swift
//  RunMate
//

import Foundation

struct AIGeneratedImage: Codable, Identifiable {
    let id: UUID
    let prompt: String
    let styleTitle: String
    let createdAt: Date
    let fileName: String
}
