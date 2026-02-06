//
//  CleaningItem.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/5.
//

import SwiftUI
import Photos

struct HomeItem: Identifiable {
    var id = UUID()
    var title: String
    var size: String
    var phAsset: PHAsset?
    var viewHeight: CGFloat
    var photoCategory: PhotoCategory
    var count: Int = 0
}
