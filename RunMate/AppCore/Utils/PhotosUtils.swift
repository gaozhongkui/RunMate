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
                    continuation.resume(returning: [])
                    return
                }

                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)

                // Limit the number of results
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
                    // Avoid using maximum size to prevent memory overflow
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

                // --- Core change: handle count limit ---
                // If -1 is passed, set fetchLimit to 0 (0 means no limit in the Photos framework)
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

    // Helper: safely fetch assets from a Collection
    private static func fetchAssetsInCollection(_ collection: PHAssetCollection?, options: PHFetchOptions) -> PHFetchResult<PHAsset> {
        if let collection = collection {
            return PHAsset.fetchAssets(in: collection, options: options)
        }
        // Return an empty result set
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

        // fetchResult.count is already affected by fetchLimit, so enumerate directly
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
