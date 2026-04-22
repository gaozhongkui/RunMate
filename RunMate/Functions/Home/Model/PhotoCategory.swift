//
//  PhotoCategory.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/5.
//

import SwiftUI

enum PhotoCategory: Equatable {
    case allVideos
    case screenshots
    case recordings
    case shortVideos(maxDuration: Double)
    
    // Custom equality comparison, ignoring the specific value of maxDuration
    static func == (lhs: PhotoCategory, rhs: PhotoCategory) -> Bool {
        switch (lhs, rhs) {
        case (.allVideos, .allVideos):
            return true
        case (.screenshots, .screenshots):
            return true
        case (.recordings, .recordings):
            return true
        case (.shortVideos, .shortVideos):
            return true  // Treat as equal as long as both are shortVideos
        default:
            return false
        }
    }
}
