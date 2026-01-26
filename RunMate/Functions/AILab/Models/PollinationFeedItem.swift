//
//  Untitled.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import Foundation

struct PollinationFeedItem: Codable, Identifiable {
    let id = UUID()
    let prompt: String
    let imageURL: String

    enum CodingKeys: String, CodingKey {
        case prompt
        case imageURL = "image_url" // 根据实际返回字段调整
    }
}
