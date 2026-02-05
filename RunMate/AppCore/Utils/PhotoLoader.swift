//
//  PhotoLoader.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/5.
//

import Foundation
import Photos
import UIKit
import Atomics

public final class PhotoLoader : Sendable {
    public static let shared = PhotoLoader()
    
    private init() {
    }
    
    func fetchAllPhotosByDate() -> PHFetchResult<PHAsset> {
        // 避免触发权限弹窗
        if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            return PHFetchResult<PHAsset>()
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        return PHAsset.fetchAssets(with: fetchOptions)
    }
    
    private func _requestImageData(for asset: PHAsset) async -> (Data, String, CGImagePropertyOrientation)? {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.resizeMode = .fast
        options.deliveryMode = .highQualityFormat
        options.version = .current
        
        return await withCheckedContinuation {c in
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) {data, uti, orientation, _ in
                if let data = data, let uti = uti {
                    c.resume(returning: (data, uti, orientation))
                } else {
                    c.resume(returning: nil)
                }
            }
        }
    }
    
    private func _getImageProperties(data: Data) -> [CFString: Any] {
        if let source = CGImageSourceCreateWithData(data as CFData, nil),
           let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            return properties
        } else {
            return [:]
        }
    }
    
    private func _getImageProperties(for asset: PHAsset) async -> [CFString: Any] {
        if let (data, _, _) = await _requestImageData(for: asset) {
            return _getImageProperties(data: data)
        } else {
            return [:]
        }
    }
    
    private func _requestHighQualityImage(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = false
        options.resizeMode = .fast
        options.version = .current
        
        return await withCheckedContinuation {c in
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .default, options: options) {image, _ in
                c.resume(returning: image)
            }
        }
    }
    
    private func _requestFastDegradedImage(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, resizeMode: PHImageRequestOptionsResizeMode = .fast) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = false
        options.resizeMode = resizeMode
        options.version = .current
        
        return await withCheckedContinuation {c in
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) {image, info in
                c.resume(returning: image)
            }
        }
    }
    
    @available(iOS 17, *)
    private func _requestFastOrSecondaryDegradedImage(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, resizeMode: PHImageRequestOptionsResizeMode = .fast) async -> [UIImage] {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.resizeMode = resizeMode
        options.version = .current
        options.allowSecondaryDegradedImage = true
        
        return await withCheckedContinuation {c in
            var firstImage: UIImage? = nil
            var timeoutTask: Task<Void, Never>?
            var requestId: PHImageRequestID?
            let resumed = ManagedAtomic<Bool>(false)
            
            func resume(firstImage: sending UIImage?, secondImage: sending UIImage?, task: Task<Void, Never>?, requestId: PHImageRequestID?) {
                if resumed.compareExchange(expected: false, desired: true, ordering: .relaxed).exchanged {
                    var result: [UIImage] = []
                    if let firstImage = firstImage {
                        result.append(firstImage)
                    }
                    if let secondImage = secondImage {
                        result.append(secondImage)
                    }
                    c.resume(returning: result)
                    task?.cancel()
                    
                    if let requestId = requestId {
                        PHImageManager.default().cancelImageRequest(requestId)
                    }
                }
            }
            
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) {image, info in
                var isDegraded: Bool = false
                
                if let info = info {
                    if requestId == nil {
                        requestId = (info[PHImageResultRequestIDKey] as? NSNumber)?.int32Value
                    }
                    isDegraded = (info[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue ?? false
                }
                
                guard let image = image else {
                    if firstImage == nil {
                        resume(firstImage: nil, secondImage: nil, task: nil, requestId: requestId)
                    }
                    return
                }
                
                if !isDegraded {
                    // should not happen, but handle for robustness
                    resume(firstImage: firstImage, secondImage: nil, task: timeoutTask, requestId: requestId)
                } else if firstImage == nil {
                    firstImage = image
                    let requestId = requestId
                    timeoutTask = Task {
                        do {
                            // wait up to 500 seconds for secondary degraded image
                            try await Task.sleep(for: .milliseconds(500))
                            resume(firstImage: image, secondImage: nil, task: nil, requestId: requestId)
                        } catch {
                        }
                    }
                } else {
                    // this is the secondary degraded image
                    resume(firstImage: firstImage, secondImage: image, task: timeoutTask, requestId: requestId)
                }
            }
        }
    }
    
    private func getCorrectedSize(asset: PHAsset, size: CGSize) -> CGSize {
        if size == PHImageManagerMaximumSize {
            return size
        }
        
        var aspectRatio = Double(asset.pixelWidth) / Double(asset.pixelHeight)
        if aspectRatio < 1 {
            aspectRatio = 1 / aspectRatio
        }
        
        return size.applying(CGAffineTransform(scaleX: aspectRatio, y: aspectRatio))
    }
    
    public func requestUIImage(for asset: PHAsset, targetSize: CGSize = PHImageManagerMaximumSize, contentMode: PHImageContentMode = .default, resizeMode: PHImageRequestOptionsResizeMode = .fast) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = false
        options.resizeMode = resizeMode
        options.version = .current
        
        let image: UIImage? = await withCheckedContinuation { c in
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) {_image, _ in
                if let _image = _image {
                    c.resume(returning: _image)
                } else {
                    c.resume(returning: nil)
                }
            }
        }
        
        if let image = image {
            return image
        } else {
            return await requestDegradedImage(for: asset, targetSize: targetSize, contentMode: contentMode, resizeMode: resizeMode)
        }
    }
    
    public func requestDegradedImage(for asset: PHAsset, targetSize: CGSize = PHImageManagerMaximumSize, contentMode: PHImageContentMode = .default, resizeMode: PHImageRequestOptionsResizeMode = .fast) async -> UIImage? {
        if #available(iOS 17, *) {
            return await _requestFastOrSecondaryDegradedImage(for: asset, targetSize: targetSize, contentMode: contentMode, resizeMode: resizeMode).last
        } else {
            return await _requestFastDegradedImage(for: asset, targetSize: targetSize, contentMode: contentMode, resizeMode: resizeMode)
        }
    }
    
    public func requestHDRUIImage(for asset: PHAsset, targetSize: CGSize = PHImageManagerMaximumSize, contentMode: PHImageContentMode = .default) async -> UIImage? {
        if #available(iOS 17.0, *) {
            return await withCheckedContinuation { c in
                PHImageManager.default().requestImageDataAndOrientation(for: asset, options: nil) { data, _, _, _ in
                    Task {
                        if let data = data {
                            var config = UIImageReader.Configuration()
                            config.prefersHighDynamicRange = true
                            config.preparesImagesForDisplay = true
                            let reader = UIImageReader(configuration: config)
                            if let image = await reader.image(data: data) {
                                c.resume(returning: image)
                                return
                            }
                        }
                        c.resume(returning: await self.requestUIImage(for: asset, targetSize: targetSize, contentMode: contentMode))
                    }
                }
            }
        } else {
            return await self.requestUIImage(for: asset, targetSize: targetSize, contentMode: contentMode)
        }
    }
}
