//
//  CustomExtensions.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import Photos
import SwiftUI
import UIKit

extension UIDevice {
    /// Determines whether the device has a notch or full-screen design
    var hasNotch: Bool {
        if UIDevice.current.model.contains("iPad") {
            return false
        }
        // Use connectedScenes to get the currently active UIWindowScene
        let scenes = UIApplication.shared.connectedScenes
        guard let windowScene = scenes.first as? UIWindowScene else { return false }

        // Get the main window
        guard let window = windowScene.windows.first else { return false }

        // If the bottom safe area inset is greater than 0, it is a full-screen device
        return window.safeAreaInsets.bottom > 0
    }
}

private struct FileInfo: Codable {
    let modificationDate: Int64
    let fileSize: Int64
}

public actor CachedFileSizeCalculator {
    private var cached: [String: FileInfo] = [:]
    private var modified: Bool
    private var saveScheduled: Bool
    private var configURL: URL?

    public static let shared = CachedFileSizeCalculator()

    public static func getAssetSize(_ asset: PHAsset) async -> Int64 {
        let result = await shared.getAssetSize(asset: asset)
        return result
    }

    private init() {
        modified = false
        saveScheduled = false
        guard
            let documentsPath = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first
        else {
            return
        }

        configURL = documentsPath.appendingPathComponent(
            "asset_size_cache.json"
        )

        do {
            if FileManager.default.fileExists(atPath: configURL!.path) {
                let data = try Data(contentsOf: configURL!)
                cached = try JSONDecoder().decode(
                    [String: FileInfo].self,
                    from: data
                )
            }
        } catch {
            NSLog("Can't load cached file size from database: \(error)")
        }
    }

    func getAssetSize(asset: PHAsset) async -> Int64 {
        let info = cached[asset.localIdentifier]
        if let info = info,
           info.modificationDate
           == Int64(asset.modificationDate?.timeIntervalSince1970 ?? 0)
        {
            return info.fileSize
        }

        let newInfo = await FileInfo(
            modificationDate: Int64(
                asset.modificationDate?.timeIntervalSince1970 ?? 0
            ),
            fileSize: calcluateAssetSize(asset: asset)
        )
        cached[asset.localIdentifier] = newInfo
        modified = true
        if !saveScheduled {
            saveScheduled = true
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await doSave()
            }
        }

        return newInfo.fileSize
    }

    private func doSave() async {
        saveScheduled = false
        if !modified {
            return
        }
        modified = false

        guard let configURL = configURL else {
            return
        }

        do {
            let json = try JSONEncoder().encode(cached)
            do {
                try json.write(to: configURL)
            } catch {
                NSLog("Failed to save cache: \(error)")
            }
        } catch {
            NSLog("Failed to serialize cache: \(error)")
        }
    }

    @MainActor
    private func calcluateAssetSize(asset: PHAsset) async -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        var size: Int64 = 0
        for resource in resources {
            if let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                size += fileSize
            }
        }

        if size == 0 {
            size = estimateVideoSize(asset)
        }

        return size
    }
}

/// Fetch the original resource size of a single PHAsset (async)
public func fetchAssetSize(_ asset: PHAsset) async -> Int64 {
    return await CachedFileSizeCalculator.getAssetSize(asset)
}

public func fetchAssetSizeWithAVAsset(_ asset: PHAsset) async -> Int64 {
    return await CachedFileSizeCalculator.getAssetSize(asset)
}

public func fetchAssetSizeEstimate(_ asset: PHAsset) async -> Int64 {
    return await CachedFileSizeCalculator.getAssetSize(asset)
}

private func estimateVideoSize(_ asset: PHAsset) -> Int64 {
    let width = Int64(asset.pixelWidth)
    let height = Int64(asset.pixelHeight)
    let duration = asset.duration

    // Calculate directly from total pixel count
    let totalPixels = width * height

    // Bits per pixel per second (adjusted by resolution)
    let bitsPerPixelPerSecond = getBitsPerPixel(totalPixels: totalPixels)

    // Estimate frame rate
    let estimatedFrameRate = getEstimatedFrameRate(asset)

    // Calculate bit rate
    let bitrate =
        Double(totalPixels) * bitsPerPixelPerSecond * estimatedFrameRate

    // Calculate file size in bytes
    let sizeInBytes = Int64(bitrate * duration / 8)

    return sizeInBytes
}

private func getBitsPerPixel(totalPixels: Int64) -> Double {
    // Higher resolution means better per-pixel compression efficiency
    switch totalPixels {
    case 0..<500_000: return 0.25 // Low resolution
    case 500_000..<1_000_000: return 0.20 // Medium resolution
    case 1_000_000..<2_000_000: return 0.15 // High resolution
    case 2_000_000..<5_000_000: return 0.12 // Full HD
    case 5_000_000..<10_000_000: return 0.10 // 2K/4K
    default: return 0.08 // Ultra-high resolution
    }
}

private func getEstimatedFrameRate(_ asset: PHAsset) -> Double {
    if asset.mediaSubtypes.contains(.videoHighFrameRate) {
        return 60.0 // High frame rate
    } else if asset.mediaSubtypes.contains(.videoTimelapse) {
        return 24.0 // Time-lapse
    } else {
        return 30.0 // Standard frame rate
    }
}


func fetchImage(
    for asset: PHAsset,
    targetSize: CGSize,
    contentMode: PHImageContentMode
) async -> UIImage? {
    return await PhotoLoader.shared.requestUIImage(for: asset)
}
