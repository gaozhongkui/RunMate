//
//  Untitled.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import Foundation

struct PollinationFeedItem: Codable, Identifiable, Hashable {
    // Use a computed property to avoid the decoder looking for an "id" key
    var id: String { imageURL } // Using imageURL as the unique identifier is more appropriate
    
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
    
    // Database-only fields (not included in JSON encoding/decoding)
    var dbId: Int64? // Database auto-increment ID for precise pagination
    var dbTimestamp: Date? // Database storage timestamp

    // Computed property for timestamp-based pagination
    var timestamp: Date {
        return dbTimestamp ?? Date()
    }
    
    // Maps JSON key names (only includes fields that need encoding/decoding)
    enum CodingKeys: String, CodingKey {
        case imageURL
        case prompt, width, height, seed, model, enhance, safe, nologo, quality, status, nsfw
        // Note: dbId and dbTimestamp are not listed here, so they are excluded from JSON encoding/decoding
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PollinationFeedItem, rhs: PollinationFeedItem) -> Bool {
        return lhs.id == rhs.id
    }
}
