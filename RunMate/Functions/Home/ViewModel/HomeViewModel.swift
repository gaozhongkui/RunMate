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

    private var mediaManager: MediaManager?
    private var progressTimer: Timer?
    
    // Track total scanned size (used for progress calculation)
    private var totalScannedBytes: Int64 = 0
    private var estimatedTotalBytes: Int64 = 0
    
    init() {
        setupInitialItems()
    }

    func loadData() async {
        if mediaManager != nil {
            return
        }
        
        await MainActor.run {
            startScanAnimation()
        }
        
        // Can now be created on a background thread
        await Task.detached {
            let manager = MediaManager()

            // Must set delegate before calling initialize,
            // otherwise all readData/fetchAssets callbacks triggered inside initialize are lost
            await MainActor.run {
                manager.delegate = self
                self.mediaManager = manager
            }

            // Initialize after delegate is in place (triggers scanning and callbacks normally)
            await manager.initialize()
        }.value
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
                viewHeight: 120,
                photoCategory: .recordings
            ),
            HomeItem(
                title: "Short Videos",
                size: "--",
                viewHeight: 240,
                photoCategory: .shortVideos(maxDuration: 0.3)
            )
        ]
    }

    private func startScanAnimation() {
        isScanning = true
        scanProgress = 0.0

        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            DispatchQueue.main.async {
                if self.scanProgress < 0.9 {
                    self.scanProgress += 0.01
                }
            }
        }
        RunLoop.main.add(progressTimer!, forMode: .common)
    }

    private func stopScanAnimation() {
        progressTimer?.invalidate()
        progressTimer = nil

        withAnimation(.easeOut(duration: 0.4)) {
            scanProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.isScanning = false
        }
    }

    /// Update all HomeItem data uniformly
    private func updateAllHomeItems() {
        guard let manager = mediaManager else { return }

        // Update left-side cards
        for index in cardLeftItems.indices {
            let category = cardLeftItems[index].photoCategory
            let (size, count, items) = getDataForCategory(category, from: manager)
            
            cardLeftItems[index].size = formatBytes(size)
            cardLeftItems[index].count = count
            cardLeftItems[index].phAsset = items.first?.phAsset
            cardLeftItems[index].id = UUID()
            cardLeftItems[index].items = items
        }
        
        // Update right-side cards
        for index in cardRightItems.indices {
            let category = cardRightItems[index].photoCategory
            let (size, count, items) = getDataForCategory(category, from: manager)
            
            cardRightItems[index].size = formatBytes(size)
            cardRightItems[index].count = count
            cardRightItems[index].phAsset = items.first?.phAsset
            cardRightItems[index].id = UUID()
            cardRightItems[index].items = items
        }
        
        // Update total size display
        updateTotalSize()
    }

    /// Get data for the specified category
    private func getDataForCategory(_ category: PhotoCategory, from manager: MediaManager) -> (size: Int64, count: Int, items: [MediaItemViewModel]) {
        switch category {
        case .allVideos:
            return (manager.allVideoSize, manager.allVideoList.count, manager.allVideoList)
        case .screenshots:
            return (manager.screenshotImageSize, manager.screenshootList.count, manager.screenshootList)
        case .recordings:
            return (manager.screenRecordingVideoSize, manager.screenRecordingVideoList.count, manager.screenRecordingVideoList)
        case .shortVideos:
            return (manager.shortVideoSize, manager.shortVideoList.count, manager.shortVideoList)
        }
    }
    
    /// Update total scanned size and total size
    private func updateTotalSize() {
        guard let manager = mediaManager else { return }

        // allVideoSize already includes shortVideoSize and screenRecordingVideoSize (they are subsets)
        // Avoid double-counting — only add screenshot size
        totalScannedBytes = manager.allVideoSize + manager.screenshotImageSize

        scannedSize = formatBytes(totalScannedBytes)
    }
    
    /// Format byte size as a human-readable string
    private func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "--" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        
        return formatter.string(fromByteCount: bytes)
    }
    
    /// Get the asset list for the specified category
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
    
    /// Delete assets
    func deleteAssets(_ assets: [PHAsset]) async throws {
        guard let manager = mediaManager else { return }
        try await manager.deleteAssets(assets: assets)
    }

    // MARK: - MediaManagerDelegate

    @MainActor
    func mediaManager(_ manager: MediaManager, didUpdateLoadingState isLoading: Bool) {}

    @MainActor
    func mediaManager(_ manager: MediaManager, didUpdateShortVideos videos: [MediaItemViewModel], totalSize: Int64) {
        updateAllHomeItems()
    }

    @MainActor
    func mediaManager(_ manager: MediaManager, didUpdateAllVideos videos: [MediaItemViewModel], totalSize: Int64) {
        updateAllHomeItems()
    }

    @MainActor
    func mediaManager(_ manager: MediaManager, didUpdateScreenRecordings recordings: [MediaItemViewModel], totalSize: Int64) {
        updateAllHomeItems()
    }

    @MainActor
    func mediaManager(_ manager: MediaManager, didUpdateScreenshots screenshots: [MediaItemViewModel], totalSize: Int64) {
        updateAllHomeItems()
    }

    @MainActor
    func mediaManager(_ manager: MediaManager, didUpdateAuthorizationStatus status: PHAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            stopScanAnimation()
        default:
            break
        }
    }

    @MainActor
    func mediaManager(_ manager: MediaManager, didFinishScanWithTime scanTime: Double) {
        updateAllHomeItems()
        stopScanAnimation()
    }
}
