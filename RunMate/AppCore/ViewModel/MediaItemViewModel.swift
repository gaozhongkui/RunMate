//
//  VideoItemViewModel.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/5.
//
import Foundation
import Photos
import SwiftUI
import UIKit

@Observable
class MediaItemViewModel: Identifiable, Hashable {
    let id: String
    let phAsset: PHAsset
    var selected: Bool
    
    let duration: Double
    let width: Int
    let height: Int
    var size: Int64
    let created: Date
    
    // 额外的便利属性
    var isLoading: Bool = false
    
    // MARK: - Initialization
    
    init(phAsset: PHAsset) {
        self.phAsset = phAsset
        self.duration = phAsset.duration
        self.width = phAsset.pixelWidth
        self.height = phAsset.pixelHeight
        self.created = phAsset.creationDate ?? Date()
        self.id = phAsset.localIdentifier
        self.size = 0
        self.selected = false
        
        // 异步加载文件大小
        Task {
            await loadFileSize()
        }
    }
    
    // MARK: - File Size Loading
    
    @MainActor
    func loadFileSize() async {
        isLoading = true
        
        let resources = PHAssetResource.assetResources(for: phAsset)
        
        if let resource = resources.first {
            // 方法1: 尝试从资源获取大小
            if let unsignedSize = resource.value(forKey: "fileSize") as? Int64 {
                size = unsignedSize
                isLoading = false
                return
            }
            
            // 方法2: 通过请求数据获取大小
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.version = .current
            
            let estimatedSize: Int64 = await withCheckedContinuation { continuation in
                PHImageManager.default().requestAVAsset(
                    forVideo: phAsset,
                    options: options
                ) { asset, _, _ in
                    guard let urlAsset = asset as? AVURLAsset else {
                        continuation.resume(returning: 0)
                        return
                    }
                    
                    do {
                        let attributes = try FileManager.default.attributesOfItem(
                            atPath: urlAsset.url.path
                        )
                        let fileSize = attributes[.size] as? Int64 ?? 0
                        continuation.resume(returning: fileSize)
                    }
                    catch {
                        // 如果获取失败,使用估算值
                        let estimatedSize = Int64(
                            Double(self.width * self.height) * self.duration * 0.5
                        )
                        continuation.resume(returning: estimatedSize)
                    }
                }
            }
            
            size = estimatedSize
        }
        
        isLoading = false
    }
    
    // MARK: - Computed Properties
    
    var aspectRatio: Double {
        guard height > 0 else { return 16.0 / 9.0 }
        return Double(width) / Double(height)
    }
    
    var resolutionString: String {
        "\(width) × \(height)"
    }
    
    var durationString: String {
        formatDuration(duration)
    }
    
    var fileSizeString: String {
        formatFileSize(size)
    }
    
    var dateString: String {
        formatDate(created)
    }
    
    var isPortrait: Bool {
        height > width
    }
    
    var isLandscape: Bool {
        width > height
    }
    
    var isSquare: Bool {
        width == height
    }
    
    var resolution: VideoResolution {
        let maxDimension = max(width, height)
        
        switch maxDimension {
        case 0..<720:
            return .sd
        case 720..<1080:
            return .hd
        case 1080..<2160:
            return .fullHD
        case 2160..<3840:
            return .ultraHD
        default:
            return .fourK
        }
    }
    
    // MARK: - Formatting Methods
    
    private func formatDuration(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "计算中..." }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = false
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        // 如果是今天,显示时间
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "今天 HH:mm"
        }
        // 如果是昨天
        else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "昨天 HH:mm"
        }
        // 如果是本周
        else if let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()),
                date > weekAgo
        {
            formatter.dateFormat = "EEEE HH:mm"
        }
        // 如果是今年
        else if Calendar.current.component(.year, from: date) == Calendar.current.component(.year, from: Date()) {
            formatter.dateFormat = "MM月dd日 HH:mm"
        }
        // 其他
        else {
            formatter.dateFormat = "yyyy年MM月dd日"
        }
        
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    // MARK: - Hashable & Equatable
    
    static func == (lhs: MediaItemViewModel, rhs: MediaItemViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Video Resolution Enum

enum VideoResolution: String, CaseIterable {
    case sd = "SD"
    case hd = "HD"
    case fullHD = "Full HD"
    case ultraHD = "2K"
    case fourK = "4K"
    
    var icon: String {
        switch self {
        case .sd: return "rectangle.fill"
        case .hd: return "rectangle.fill.badge.checkmark"
        case .fullHD: return "rectangle.fill.badge.plus"
        case .ultraHD: return "rectangle.portrait.fill"
        case .fourK: return "4k.tv.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .sd: return .gray
        case .hd: return .blue
        case .fullHD: return .green
        case .ultraHD: return .orange
        case .fourK: return .purple
        }
    }
}

// MARK: - Video Thumbnail Cache

actor ThumbnailCache {
    static let shared = ThumbnailCache()
    
    private var cache: [String: UIImage] = [:]
    private let maxCacheSize = 100 // 最多缓存100个缩略图
    
    func getThumbnail(for id: String) -> UIImage? {
        cache[id]
    }
    
    func setThumbnail(_ image: UIImage, for id: String) {
        // 如果缓存超过限制,清除最旧的一半
        if cache.count >= maxCacheSize {
            let keysToRemove = Array(cache.keys.prefix(maxCacheSize / 2))
            keysToRemove.forEach { cache.removeValue(forKey: $0) }
        }
        
        cache[id] = image
    }
    
    func clearCache() {
        cache.removeAll()
    }
}

// MARK: - Thumbnail Loader Extension

extension MediaItemViewModel {
    func loadThumbnail(size: CGSize = CGSize(width: 140, height: 100)) async -> UIImage? {
        // 先检查缓存
        if let cached = await ThumbnailCache.shared.getThumbnail(for: id) {
            return cached
        }
        
        let scale = UIScreen.main.scale
        let targetSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        
        let image: UIImage? = await withCheckedContinuation { continuation in
            var hasResumed = false
            PHImageManager.default().requestImage(
                for: phAsset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { result, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let isError = (info?[PHImageErrorKey] != nil)
                
                if !isDegraded, !isError, !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: result)
                }
                else if isError, !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: nil)
                }
            }
        }
        
        // 缓存结果
        if let image = image {
            await ThumbnailCache.shared.setThumbnail(image, for: id)
        }
        
        return image
    }
}
