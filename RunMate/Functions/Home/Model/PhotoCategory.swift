//
//  PhotoCategory.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/5.
//

import SwiftUI

enum PhotoCategory {
    case allVideos
    case screenshots
    case recordings
    case shortVideos(maxDuration: TimeInterval)
}
