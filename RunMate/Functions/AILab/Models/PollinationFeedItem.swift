//
//  Untitled.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import Foundation

struct PollinationFeedItem: Decodable, Identifiable {
    // 使用计算属性，避免解码器寻找 "id" 键
    var id: UUID { UUID() }
    
    let imageURL: String
    let prompt: String?
    let width: Int?
    let height: Int?
    let seed: Int?
    let model: String?
    let enhance: Bool?
    let safe: Bool?
    let nologo: Bool?
    let quality: String?
    let status: String?
    let nsfw: Bool?
    
    // 映射 JSON 键名（如果 API 返回的是 image_url）
    enum CodingKeys: String, CodingKey {
        case imageURL = "imageURL" // 确保这与 API 返回的键一致
        case prompt, width, height, seed, model, enhance, safe, nologo, quality, status, nsfw
    }
}
