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
    /// 判断设备是否为全面屏（或刘海屏）
    var hasNotch: Bool {
        if UIDevice.current.model.contains("iPad") {
            return false
        }
        // 使用 connectedScenes 获取当前活跃的 UIWindowScene
        let scenes = UIApplication.shared.connectedScenes
        guard let windowScene = scenes.first as? UIWindowScene else { return false }

        // 获取主窗口
        guard let window = windowScene.windows.first else { return false }

        // 如果底部安全区域大于 0，则为全面屏设备
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

/// 获取单个 PHAsset 的原始资源大小（异步读取）
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

    // 直接使用像素总数计算
    let totalPixels = width * height

    // 每像素每秒的比特数（根据分辨率调整）
    let bitsPerPixelPerSecond = getBitsPerPixel(totalPixels: totalPixels)

    // 估算帧率
    let estimatedFrameRate = getEstimatedFrameRate(asset)

    // 计算比特率
    let bitrate =
        Double(totalPixels) * bitsPerPixelPerSecond * estimatedFrameRate

    // 计算文件大小（字节）
    let sizeInBytes = Int64(bitrate * duration / 8)

    return sizeInBytes
}

private func getBitsPerPixel(totalPixels: Int64) -> Double {
    // 分辨率越高，每像素压缩效率越好
    switch totalPixels {
    case 0..<500_000: return 0.25 // 低分辨率
    case 500_000..<1_000_000: return 0.20 // 中等分辨率
    case 1_000_000..<2_000_000: return 0.15 // 高分辨率
    case 2_000_000..<5_000_000: return 0.12 // 全高清
    case 5_000_000..<10_000_000: return 0.10 // 2K/4K
    default: return 0.08 // 超高分辨率
    }
}

private func getEstimatedFrameRate(_ asset: PHAsset) -> Double {
    if asset.mediaSubtypes.contains(.videoHighFrameRate) {
        return 60.0 // 高帧率
    } else if asset.mediaSubtypes.contains(.videoTimelapse) {
        return 24.0 // 延时摄影
    } else {
        return 30.0 // 标准帧率
    }
}


func fetchImage(
    for asset: PHAsset,
    targetSize: CGSize,
    contentMode: PHImageContentMode
) async -> UIImage? {
    return await PhotoLoader.shared.requestUIImage(for: asset)
}
