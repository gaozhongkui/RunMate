//
//  PhotosUtils.swift
//  ARKitTest
//
//  Created by gaozhongkui on 2026/1/15.
//

import Photos
import SwiftUI

class PhotosUtils {
    static func fetchPhotos(limit: Int) async -> [UIImage] {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    print("gzk 用户拒绝访问相册")
                    continuation.resume(returning: [])
                    return
                }

                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                
                print("gzk 总共找到 \(allPhotos.count) 张图片")

                // 限制获取数量
                let count = min(limit, allPhotos.count)
                var selectedAssets: [PHAsset] = []
                for i in 0..<count {
                    selectedAssets.append(allPhotos.object(at: i))
                }

                var images: [UIImage] = []
                let manager = PHImageManager.default()
                let option = PHImageRequestOptions()
                option.isSynchronous = false
                option.deliveryMode = .highQualityFormat

                let group = DispatchGroup()

                for asset in selectedAssets {
                    group.enter()
                    // 建议不要用最大尺寸，防止内存爆掉
                    manager.requestImage(for: asset,
                                         targetSize: CGSize(width: 500, height: 500),
                                         contentMode: .aspectFill,
                                         options: option)
                    { image, _ in
                        if let img = image {
                            images.append(img)
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    continuation.resume(returning: images)
                }
            }
        }
    }

}
