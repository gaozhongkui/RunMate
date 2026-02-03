//
//  Untitled.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import Foundation

struct PollinationFeedItem: Codable, Identifiable {
    // 使用计算属性，避免解码器寻找 "id" 键
    var id: String { imageURL } // 使用 imageURL 作为唯一标识更合理
    
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
    
    // 数据库专用字段（不参与 JSON 解码/编码）
    var dbId: Int64?          // 数据库自增 ID，用于精确分页
    var dbTimestamp: Date?    // 数据库存储时间
    
    // 用于时间戳分页的计算属性
    var timestamp: Date {
        return dbTimestamp ?? Date()
    }
    
    // 映射 JSON 键名（只包含需要编解码的字段）
    enum CodingKeys: String, CodingKey {
        case imageURL = "imageURL"
        case prompt, width, height, seed, model, enhance, safe, nologo, quality, status, nsfw
        // 注意：dbId 和 dbTimestamp 不在这里，所以不会参与 JSON 编解码
    }
}
