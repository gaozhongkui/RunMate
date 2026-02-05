//
//  CleaningItem.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/5.
//

import SwiftUI
import Photos

struct HomeItem: Identifiable {
    let id = UUID()
    let title: String
    var size: String
    var imageName: String
    var viewHeight: CGFloat
    var photoCategory: PhotoCategory
    var phAsset: PHAsset?
}
