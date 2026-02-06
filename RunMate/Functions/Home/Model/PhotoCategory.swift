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
    
    // 自定义相等性比较，忽略 maxDuration 的具体值
    static func == (lhs: PhotoCategory, rhs: PhotoCategory) -> Bool {
        switch (lhs, rhs) {
        case (.allVideos, .allVideos):
            return true
        case (.screenshots, .screenshots):
            return true
        case (.recordings, .recordings):
            return true
        case (.shortVideos, .shortVideos):
            return true  // 只要都是 shortVideos 就认为相等
        default:
            return false
        }
    }
}
