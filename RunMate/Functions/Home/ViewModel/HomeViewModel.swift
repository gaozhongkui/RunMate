//
//  HomeViewModel.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/5.
//

import Foundation
import Photos
import SwiftUI

@Observable
class HomeViewModel: MediaManagerDelegate {
    var cardLeftItems: [HomeItem] = []
    var cardRightItems: [HomeItem] = []
    var isScanning = true
    var scanProgress: CGFloat = 0.0
    var scannedSize = "0 GB"
    var totalSize = "0 GB"

    private var mediaManager: MediaManager?
    private var progressTimer: Timer?
    
    // 记录总扫描的大小（用于进度计算）
    private var totalScannedBytes: Int64 = 0
    private var estimatedTotalBytes: Int64 = 0

    init() {
        setupInitialItems()
    }

    @MainActor
    func loadData() async {
        // 创建 MediaManager 并设置代理
        let manager = MediaManager()
        manager.delegate = self
        mediaManager = manager
        
        // 开始扫描动画
        startScanAnimation()
        
        // 请求权限并开始加载数据
        let status = await manager.requestAuthorization()
        print("相册权限状态: \(status)")
    }

    private func setupInitialItems() {
        cardLeftItems = [
            HomeItem(
                title: "All Videos",
                size: "--",
                viewHeight: 180,
                photoCategory: .allVideos
            ),
            HomeItem(
                title: "Screenshots",
                size: "--",
                viewHeight: 180,
                photoCategory: .screenshots
            )
        ]
        
        cardRightItems = [
            HomeItem(
                title: "Recordings",
                size: "--",
                viewHeight: 150,
                photoCategory: .recordings
            ),
            HomeItem(
                title: "Short Videos",
                size: "--",
                viewHeight: 350,
                photoCategory: .shortVideos(maxDuration: 0.3)
            )
        ]
    }

    private func startScanAnimation() {
        isScanning = true
        scanProgress = 0.0
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            // 根据实际加载进度更新
            if self.scanProgress < 0.95 {
                self.scanProgress += 0.01
            }
        }
    }
    
    private func stopScanAnimation() {
        progressTimer?.invalidate()
        progressTimer = nil
        
        // 完成动画
        withAnimation {
            scanProgress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isScanning = false
        }
    }

    /// 核心方法：更新指定分类的 HomeItem
    private func updateHomeItem(category: PhotoCategory, size: Int64, count: Int, asset: PHAsset?) {
        let formattedSize = formatBytes(size)
        
        // 更新左侧数组
        if let index = cardLeftItems.firstIndex(where: { $0.photoCategory == category }) {
            cardLeftItems[index].size = formattedSize
            cardLeftItems[index].count = count
            cardLeftItems[index].phAsset = asset
            cardLeftItems[index].id = UUID()
        }
        
        // 更新右侧数组
        if let index = cardRightItems.firstIndex(where: { $0.photoCategory == category }) {
            cardRightItems[index].size = formattedSize
            cardRightItems[index].count = count
            cardRightItems[index].phAsset = asset
            cardRightItems[index].id = UUID()
        }
        
        // 更新总大小显示
        updateTotalSize()
    }
    
    /// 更新总扫描大小和总大小
    private func updateTotalSize() {
        guard let manager = mediaManager else { return }
        
        // 计算已扫描的总大小
        totalScannedBytes = manager.allVideoSize +
            manager.shortVideoSize +
            manager.screenRecordingVideoSize +
            manager.screenshotImageSize
        
        scannedSize = formatBytes(totalScannedBytes)
        
        // 这里可以根据缓存或其他方式估算总大小
        // 暂时使用扫描的大小作为总大小
        totalSize = formatBytes(totalScannedBytes)
    }
    
    /// 格式化字节大小
    private func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "--" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        
        return formatter.string(fromByteCount: bytes)
    }
    
    /// 获取指定分类的资产列表
    func getAssets(for category: PhotoCategory) -> [MediaItemViewModel] {
        guard let manager = mediaManager else { return [] }
        
        switch category {
        case .allVideos:
            return manager.allVideoList
        case .screenshots:
            return manager.screenshootList
        case .recordings:
            return manager.screenRecordingVideoList
        case .shortVideos:
            return manager.shortVideoList
        }
    }
    
    /// 删除资产
    func deleteAssets(_ assets: [PHAsset]) async throws {
        guard let manager = mediaManager else { return }
        try await manager.deleteAssets(assets: assets)
    }

    func startCleaning() {
        print("开始清理...")
        // TODO: 实现清理逻辑
    }

    // MARK: - MediaManagerDelegate

    @MainActor
    func mediaManager(_ manager: MediaManager, didUpdateLoadingState isLoading: Bool) {
        print("加载状态: \(isLoading)")
        
        // 如果加载完成，停止扫描动画
        if !isLoading {
            stopScanAnimation()
        }
    }

    @MainActor
    func mediaManager(_ manager: MediaManager, didUpdateShortVideos videos: [MediaItemViewModel], totalSize: Int64) {
        print("短视频更新: \(videos.count) 个，总大小: \(formatBytes(totalSize))")
        
        updateHomeItem(
            category: .shortVideos(maxDuration: 0.3),
            size: totalSize,
            count: videos.count,
            asset: videos.first?.phAsset
        )
    }

    @MainActor
    func mediaManager(_ manager: MediaManager, didUpdateAllVideos videos: [MediaItemViewModel], totalSize: Int64) {
        print("所有视频更新: \(videos.count) 个，总大小: \(formatBytes(totalSize))")
        
        updateHomeItem(
            category: .allVideos,
            size: totalSize,
            count: videos.count,
            asset: videos.first?.phAsset
        )
    }

    @MainActor
    func mediaManager(_ manager: MediaManager, didUpdateScreenRecordings recordings: [MediaItemViewModel], totalSize: Int64) {
        print("录屏更新: \(recordings.count) 个，总大小: \(formatBytes(totalSize))")
        
        updateHomeItem(
            category: .recordings,
            size: totalSize,
            count: recordings.count,
            asset: recordings.first?.phAsset
        )
    }

    @MainActor
    func mediaManager(_ manager: MediaManager, didUpdateScreenshots screenshots: [MediaItemViewModel], totalSize: Int64) {
        print("截屏更新: \(screenshots.count) 个，总大小: \(formatBytes(totalSize))")
        
        updateHomeItem(
            category: .screenshots,
            size: totalSize,
            count: screenshots.count,
            asset: screenshots.first?.phAsset
        )
    }

    @MainActor
    func mediaManager(_ manager: MediaManager, didUpdateAuthorizationStatus status: PHAuthorizationStatus) {
        print("权限状态更新: \(status)")
        
        // 处理权限状态变化
        switch status {
        case .authorized, .limited:
            print("✅ 已获得相册权限")
        case .denied, .restricted:
            print("❌ 相册权限被拒绝")
            stopScanAnimation()
        case .notDetermined:
            print("⚠️ 尚未请求权限")
        @unknown default:
            break
        }
    }

    @MainActor
    func mediaManager(_ manager: MediaManager, didFinishScanWithTime scanTime: Double) {
        print("✅ 扫描完成，耗时: \(scanTime) 秒")
        
        // 确保动画完成
        stopScanAnimation()
    }
}
