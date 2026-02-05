//
//  PHPhotoLibrary+Extension.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/5.
//

import Foundation
import Photos
import UIKit

func fetchImage(
    for asset: PHAsset,
    targetSize: CGSize,
    contentMode: PHImageContentMode
) async -> UIImage? {
    return await PhotoLoader.shared.requestUIImage(for: asset)
}
