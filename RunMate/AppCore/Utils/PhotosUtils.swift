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

                // 限制获取数量
                let count = min(limit, allPhotos.count)
                var selectedAssets: [PHAsset] = []
                for i in 0 ..< count {
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

    static func fetchAssets(for category: PhotoCategory, limit: Int = -1) async -> [UIImage] {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized || status == .limited else {
                    continuation.resume(returning: [])
                    return
                }

                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

                // --- 核心修改：处理限制数量 ---
                // 如果传入 -1，则 fetchLimit 设为 0 (Photos 框架中 0 代表不限制)
                fetchOptions.fetchLimit = limit < 0 ? 0 : limit

                var fetchResult: PHFetchResult<PHAsset>

                switch category {
                case .allVideos:
                    fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)

                case .screenshots:
                    let albums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenshots, options: nil)
                    fetchResult = fetchAssetsInCollection(albums.firstObject, options: fetchOptions)

                case .recordings:
                    let albums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenRecordings, options: nil)
                    fetchResult = fetchAssetsInCollection(albums.firstObject, options: fetchOptions)

                case .shortVideos(let maxDuration):
                    fetchOptions.predicate = NSPredicate(format: "mediaType = %d AND duration <= %f", PHAssetMediaType.video.rawValue, maxDuration)
                    fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
                }

                self.loadImages(from: fetchResult, completion: { images in
                    continuation.resume(returning: images)
                })
            }
        }
    }

    // 辅助方法：安全获取 Collection 中的资源
    private static func fetchAssetsInCollection(_ collection: PHAssetCollection?, options: PHFetchOptions) -> PHFetchResult<PHAsset> {
        if let collection = collection {
            return PHAsset.fetchAssets(in: collection, options: options)
        }
        // 返回一个空的结果集
        return PHAsset.fetchAssets(with: .image, options: options)
    }

    private static func loadImages(from fetchResult: PHFetchResult<PHAsset>, completion: @escaping ([UIImage]) -> Void) {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.isSynchronous = false
        option.deliveryMode = .highQualityFormat

        let group = DispatchGroup()
        var images: [UIImage] = []
        let imageQueue = DispatchQueue(label: "com.photosutils.images")

        // fetchResult.count 已经受 fetchLimit 影响了，所以直接遍历即可
        fetchResult.enumerateObjects { asset, _, _ in
            group.enter()
            manager.requestImage(for: asset,
                                 targetSize: CGSize(width: 500, height: 500),
                                 contentMode: .aspectFill,
                                 options: option)
            { image, _ in
                if let img = image {
                    imageQueue.async {
                        images.append(img)
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(images)
        }
    }
}
