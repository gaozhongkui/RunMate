import AVFoundation
import Foundation
import Photos
import SwiftUI

let SHORT_VIDEO_TIME: Double = 6.0
let LARGE_VIDEO_FILE_SIZE: Int64 = 100 * 1024 * 1024

/// Cache data structure
struct MediaCacheData: Codable {
    // Screenshots
    var screenshotTotalSize: Int64
    var latestScreenshotAssetId: String?
    var screenshotTotalCount: Int

    // Screen recordings
    var screenRecordingTotalSize: Int64
    var latestScreenRecordingAssetId: String?
    var screenRecordingTotalCount: Int

    var allVideoTotalSize: Int64
    var latestAllVideoAssetId: String?
    var allVideoTotalCount: Int

    // Short videos
    var shortVideoTotalSize: Int64
    var latestShortVideoAssetId: String?
    var shortVideoTotalCount: Int
}

struct FetchResult: @unchecked Sendable {
    var shortVideoSize: Int64 = 0
    var screenRecordingVideoSize: Int64 = 0
    var allVideoSize: Int64 = 0
    var screenshotImageSize: Int64 = 0

    var shortVideoList: [MediaItemViewModel] = []
    var allVideoList: [MediaItemViewModel] = []
    var screenRecordingVideoList: [MediaItemViewModel] = []
    var screenshootList: [MediaItemViewModel] = []
    var allAssets: [MediaItemViewModel] = []

    var videoSize: Int64 = 0
}

/// Callback protocol for media data updates
protocol MediaManagerDelegate: AnyObject {
    /// Loading state changed
    func mediaManager(_ manager: MediaManager, didUpdateLoadingState isLoading: Bool)

    /// Short videos data updated
    func mediaManager(_ manager: MediaManager, didUpdateShortVideos videos: [MediaItemViewModel], totalSize: Int64)

    /// All videos data updated
    func mediaManager(_ manager: MediaManager, didUpdateAllVideos videos: [MediaItemViewModel], totalSize: Int64)

    /// Screen recordings data updated
    func mediaManager(_ manager: MediaManager, didUpdateScreenRecordings recordings: [MediaItemViewModel], totalSize: Int64)

    /// Screenshots data updated
    func mediaManager(_ manager: MediaManager, didUpdateScreenshots screenshots: [MediaItemViewModel], totalSize: Int64)

    /// Authorization status changed
    func mediaManager(_ manager: MediaManager, didUpdateAuthorizationStatus status: PHAuthorizationStatus)

    /// Scan completed
    func mediaManager(_ manager: MediaManager, didFinishScanWithTime scanTime: Double)
}

// Optional default implementations
extension MediaManagerDelegate {
    func mediaManager(_ manager: MediaManager, didUpdateLoadingState isLoading: Bool) {}
    func mediaManager(_ manager: MediaManager, didUpdateShortVideos videos: [MediaItemViewModel], totalSize: Int64) {}
    func mediaManager(_ manager: MediaManager, didUpdateAllVideos videos: [MediaItemViewModel], totalSize: Int64) {}
    func mediaManager(_ manager: MediaManager, didUpdateScreenRecordings recordings: [MediaItemViewModel], totalSize: Int64) {}
    func mediaManager(_ manager: MediaManager, didUpdateScreenshots screenshots: [MediaItemViewModel], totalSize: Int64) {}
    func mediaManager(_ manager: MediaManager, didUpdateAuthorizationStatus status: PHAuthorizationStatus) {}
    func mediaManager(_ manager: MediaManager, didFinishScanWithTime scanTime: Double) {}
}

// Remove class-level @MainActor
class MediaManager: NSObject, PHPhotoLibraryChangeObserver {
    // MARK: - Properties
    
    /// Short videos (duration <= 6 seconds)
    @MainActor private(set) var shortVideoList: [MediaItemViewModel] = []
    /// All videos list
    @MainActor private(set) var allVideoList: [MediaItemViewModel] = []
    /// Screen recordings
    @MainActor private(set) var screenRecordingVideoList: [MediaItemViewModel] = []
    /// Screenshots
    @MainActor private(set) var screenshootList: [MediaItemViewModel] = []

    /// Total size of all videos
    @MainActor private(set) var allVideoSize: Int64 = 0
    @MainActor private(set) var shortVideoSize: Int64 = 0
    @MainActor private(set) var screenRecordingVideoSize: Int64 = 0
    @MainActor private(set) var screenshotImageSize: Int64 = 0

    @MainActor private(set) var isLoading: Bool = false {
        didSet {
            delegate?.mediaManager(self, didUpdateLoadingState: isLoading)
        }
    }

    // These properties do not require main-thread isolation
    private(set) var localCache: MediaCacheData?

    // Manage fetchTask in an actor-safe manner
    private let fetchTaskLock = NSLock()
    private var _fetchTask: Task<Void, Never>?
    
    private var allAssetsFetchResult: PHFetchResult<PHAsset>?

    // Cache keys
    private let cacheKey = "AssetsLibraryCache"
    private let cachePermissionKey = "PhotoLibraryPermissionCache"

    /// Scan statistics
    @MainActor private(set) var scanTime: Double = 0.0

    @MainActor private(set) var authorizationStatus: PHAuthorizationStatus = .notDetermined {
        didSet {
            delegate?.mediaManager(self, didUpdateAuthorizationStatus: authorizationStatus)
        }
    }
    
    // MARK: - Delegate
    
    @MainActor weak var delegate: MediaManagerDelegate?
    
    // MARK: - Initialization
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    // init is marked nonisolated — does not run on the main thread
    nonisolated override init() {
        super.init()
        // Do not perform any time-consuming work inside init
    }

    // Explicit initialization method
    nonisolated func initialize() async {
        await checkAuthorization()
    }
    
    // MARK: - PHPhotoLibraryChangeObserver
    
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            if self.isLoading {
                await self.fetchAssets(isInitialLoad: false)
                return
            }

            if let fetchResult = self.allAssetsFetchResult,
               let changes = changeInstance.changeDetails(for: fetchResult)
            {
                // Update the stored FetchResult
                self.allAssetsFetchResult = changes.fetchResultAfterChanges
                if changes.hasIncrementalChanges {
                    // Get indices of removed objects
                    if let removedIndexes = changes.removedIndexes, !removedIndexes.isEmpty {
                        let removedAssets = changes.removedObjects
                        // Remove from existing lists
                        let removedIds = Set(removedAssets.map { $0.localIdentifier })
                        self.removeAssets(ids: removedIds)
                    }

                    if let insertedIndexes = changes.insertedIndexes, !insertedIndexes.isEmpty {
                        await self.fetchAssets(isInitialLoad: false)
                    }
                } else {
                    await self.fetchAssets(isInitialLoad: false)
                }
            } else {
                await self.fetchAssets(isInitialLoad: false)
            }
        }
    }

    // MARK: - Public Methods

    @MainActor
    func readData() {
        // Load cached data first
        restoreFromCache()

        Task.detached(priority: .userInitiated) { [weak self] in
            // Silent background update
            await self?.fetchAssets()
        }
    }

    /// Request authorization (called externally)
    nonisolated func requestAuthorization() async -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await checkPermissionChange(newStatus: newStatus)
            await MainActor.run {
                self.authorizationStatus = newStatus
            }
            await regeisterPhotoLibraryListener()
        } else {
            await checkPermissionChange(newStatus: status)
            await MainActor.run {
                self.authorizationStatus = status
            }
            await regeisterPhotoLibraryListener()
        }
        return await MainActor.run { self.authorizationStatus }
    }

    /// Delete specified assets (removes from both photo library and memory)
    /// - Parameter assets: Array of PHAssets to delete
    /// - Returns: Whether deletion succeeded
    /// - Throws: Errors encountered during deletion
    @discardableResult
    nonisolated func deleteAssets(assets: [PHAsset]) async throws -> Bool {
        guard !assets.isEmpty else { return false }
        // Get identifiers
        let identifiers = assets.map { $0.localIdentifier }
        // Use a non-actor-isolated helper to perform the deletion
        let success = try await AssetDeleter.deleteAssets(identifiers: identifiers)

        if success {
            // Remove from memory and update statistics
            let ids = Set(identifiers)
            await MainActor.run {
                self.removeAssets(ids: ids)
            }
        }

        return success
    }

    // MARK: - Private Methods

    /// Register photo library change observer when permission is already granted
    private nonisolated func checkAuthorization() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status != .notDetermined {
            // Check whether the permission status has changed
            await checkPermissionChange(newStatus: status)
            await MainActor.run {
                self.authorizationStatus = status
            }
            await regeisterPhotoLibraryListener()
        }
    }

    /// Check for permission changes and clear cache if changed
    private nonisolated func checkPermissionChange(newStatus: PHAuthorizationStatus) async {
        let cachedPermission = UserDefaults.standard.integer(forKey: cachePermissionKey)
        let newPermissionValue = newStatus.rawValue

        // If a cached permission value exists and differs from the current one, clear localCache
        if cachedPermission != 0, cachedPermission != newPermissionValue {
            localCache = nil
            UserDefaults.standard.removeObject(forKey: cacheKey)
        }

        // Save current permission status
        UserDefaults.standard.set(newPermissionValue, forKey: cachePermissionKey)
    }

    private nonisolated func regeisterPhotoLibraryListener() async {
        let status = await MainActor.run { self.authorizationStatus }
        if status == .authorized || status == .limited {
            PHPhotoLibrary.shared().register(self)
            await MainActor.run {
                self.readData()
            }
        }
    }

    /// Remove assets with the specified IDs from all lists
    @MainActor
    private func removeAssets(ids: Set<String>) {
        // Short Video
        let shortToRemove = shortVideoList.filter { ids.contains($0.phAsset.localIdentifier) }
        if !shortToRemove.isEmpty {
            shortVideoList.removeAll { ids.contains($0.phAsset.localIdentifier) }
            let sizeToRemove = shortToRemove.reduce(0) { $0 + $1.size }
            shortVideoSize -= sizeToRemove

            // Notify delegate
            delegate?.mediaManager(self, didUpdateShortVideos: shortVideoList, totalSize: shortVideoSize)
        }

        let allVideoToRemove = allVideoList.filter { ids.contains($0.phAsset.localIdentifier) }
        if !allVideoToRemove.isEmpty {
            allVideoList.removeAll { ids.contains($0.phAsset.localIdentifier) }
            let sizeToRemove = allVideoToRemove.reduce(0) { $0 + $1.size }
            allVideoSize -= sizeToRemove

            // Notify delegate
            delegate?.mediaManager(self, didUpdateAllVideos: allVideoList, totalSize: allVideoSize)
        }

        let screenRecordingToRemove = screenRecordingVideoList.filter { ids.contains($0.phAsset.localIdentifier) }
        if !screenRecordingToRemove.isEmpty {
            screenRecordingVideoList.removeAll { ids.contains($0.phAsset.localIdentifier) }
            let sizeToRemove = screenRecordingToRemove.reduce(0) { $0 + $1.size }
            screenRecordingVideoSize -= sizeToRemove

            // Notify delegate
            delegate?.mediaManager(self, didUpdateScreenRecordings: screenRecordingVideoList, totalSize: screenRecordingVideoSize)
        }

        let screenshotToRemove = screenshootList.filter { ids.contains($0.phAsset.localIdentifier) }
        if !screenshotToRemove.isEmpty {
            screenshootList.removeAll { ids.contains($0.phAsset.localIdentifier) }
            let sizeToRemove = screenshotToRemove.reduce(0) { $0 + $1.size }
            screenshotImageSize -= sizeToRemove

            // Notify delegate
            delegate?.mediaManager(self, didUpdateScreenshots: screenshootList, totalSize: screenshotImageSize)
        }

        // Save cache
        saveCache()
    }

    private nonisolated func fetchAssets(isInitialLoad: Bool = true) async {
        // Cancel the previous task in a thread-safe manner
        fetchTaskLock.lock()
        _fetchTask?.cancel()
        fetchTaskLock.unlock()

        let task = Task {
            await MainActor.run {
                self.isLoading = true
            }
            
            defer {
                Task { @MainActor in
                    self.isLoading = false
                }
            }

            let status = await MainActor.run { self.authorizationStatus }
            guard status == .authorized || status == .limited else { return }

            let startTime = Date()

            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
            self.allAssetsFetchResult = fetchResult

            var assets: [PHAsset] = []
            fetchResult.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }

            if isInitialLoad {
                // Initial load: progressive update
                await self.processAssetsProgressively(assets)
            } else {
                // Photo library change: silent fetch, one-shot update
                await self.processAssetsAtOnce(assets)
            }

            let endTime = Date()
            let scanTime = endTime.timeIntervalSince(startTime)
            await MainActor.run {
                self.scanTime = scanTime
            }
            // Notify delegate that scan is complete
            await MainActor.run {
                self.delegate?.mediaManager(self, didFinishScanWithTime: scanTime)
            }
        }

        // Save task reference
        fetchTaskLock.lock()
        _fetchTask = task
        fetchTaskLock.unlock()

        await task.value
    }

    private nonisolated func processAsset(_ asset: PHAsset) async -> FetchResult {
        var result = FetchResult()

        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first else { return result }

        var size: Int64 = 0
        if let unsignedSize = resource.value(forKey: "fileSize") as? Int {
            size = Int64(unsignedSize)
        }

        let vm = MediaItemViewModel(phAsset: asset)

        switch asset.mediaType {
        case .video:
            result.videoSize += size
            result.allVideoList.append(vm)
            result.allVideoSize += size

            if let duration = await getVideoDuration(for: asset),
               duration <= SHORT_VIDEO_TIME
            {
                result.shortVideoList.append(vm)
                result.shortVideoSize += size
            }

            if asset.mediaSubtypes.contains(.videoScreenRecording) {
                result.screenRecordingVideoList.append(vm)
                result.screenRecordingVideoSize += size
            }

        case .image:
            if asset.mediaSubtypes.contains(.photoScreenshot) {
                result.screenshootList.append(vm)
                result.screenshotImageSize += size
            }

        default:
            break
        }

        return result
    }

    private nonisolated func getVideoDuration(for asset: PHAsset) async -> Double? {
        return await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.version = .current
            options.deliveryMode = .fastFormat

            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                if let avAsset = avAsset {
                    let duration = CMTimeGetSeconds(avAsset.duration)
                    continuation.resume(returning: duration)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    /// Initial load: process in batches with progressive UI updates
    private nonisolated func processAssetsProgressively(_ assets: [PHAsset]) async {
        let batchSize = 100
        var processedCount = 0
        var isFirstBatch = true

        while processedCount < assets.count {
            if Task.isCancelled { break }

            let startIndex = processedCount
            let endIndex = min(processedCount + batchSize, assets.count)
            let batch = Array(assets[startIndex ..< endIndex])


            // Process the current batch
            await withTaskGroup(of: FetchResult.self) { group in
                for asset in batch {
                    if Task.isCancelled { break }
                    group.addTask {
                        await self.processAsset(asset)
                    }
                }

                // Collect results for the current batch
                var batchResult = FetchResult()
                for await result in group {
                    if Task.isCancelled { break }

                    batchResult.shortVideoList.append(contentsOf: result.shortVideoList)
                    batchResult.shortVideoSize += result.shortVideoSize

                    batchResult.allVideoList.append(contentsOf: result.allVideoList)
                    batchResult.allVideoSize += result.allVideoSize

                    batchResult.screenRecordingVideoList.append(contentsOf: result.screenRecordingVideoList)
                    batchResult.screenRecordingVideoSize += result.screenRecordingVideoSize

                    batchResult.screenshootList.append(contentsOf: result.screenshootList)
                    batchResult.screenshotImageSize += result.screenshotImageSize

                    batchResult.videoSize += result.videoSize
                }

                // Immediately update UI (progressive)
                if !Task.isCancelled {
                    let isFirst = isFirstBatch

                    await MainActor.run {
                        // Clear lists only on the first batch to avoid a blank screen
                        if isFirst {
                            self.shortVideoList = []
                            self.allVideoList = []
                            self.screenRecordingVideoList = []
                            self.screenshootList = []

                            self.shortVideoSize = 0
                            self.allVideoSize = 0
                            self.screenRecordingVideoSize = 0
                            self.screenshotImageSize = 0
                        }

                        self.shortVideoList.append(contentsOf: batchResult.shortVideoList)
                        self.allVideoList.append(contentsOf: batchResult.allVideoList)
                        self.screenRecordingVideoList.append(contentsOf: batchResult.screenRecordingVideoList)
                        self.screenshootList.append(contentsOf: batchResult.screenshootList)

                        self.shortVideoSize += batchResult.shortVideoSize
                        self.allVideoSize += batchResult.allVideoSize
                        self.screenRecordingVideoSize += batchResult.screenRecordingVideoSize
                        self.screenshotImageSize += batchResult.screenshotImageSize
                        
                        // Notify delegate of data update
                        self.delegate?.mediaManager(self, didUpdateShortVideos: self.shortVideoList, totalSize: self.shortVideoSize)
                        self.delegate?.mediaManager(self, didUpdateAllVideos: self.allVideoList, totalSize: self.allVideoSize)
                        self.delegate?.mediaManager(self, didUpdateScreenRecordings: self.screenRecordingVideoList, totalSize: self.screenRecordingVideoSize)
                        self.delegate?.mediaManager(self, didUpdateScreenshots: self.screenshootList, totalSize: self.screenshotImageSize)
                    }

                    isFirstBatch = false
                }
            }

            processedCount = endIndex
        }

        // Save cache after processing is complete
        saveCache()
    }

    /// Photo library change: silent fetch, one-shot UI update
    private nonisolated func processAssetsAtOnce(_ assets: [PHAsset]) async {
        await withTaskGroup(of: FetchResult.self) { group in
            for asset in assets {
                if Task.isCancelled { break }
                group.addTask {
                    await self.processAsset(asset)
                }
            }

            var finalResult = FetchResult()
            for await result in group {
                if Task.isCancelled { break }

                finalResult.shortVideoList.append(contentsOf: result.shortVideoList)
                finalResult.shortVideoSize += result.shortVideoSize

                finalResult.allVideoList.append(contentsOf: result.allVideoList)
                finalResult.allVideoSize += result.allVideoSize

                finalResult.screenRecordingVideoList.append(contentsOf: result.screenRecordingVideoList)
                finalResult.screenRecordingVideoSize += result.screenRecordingVideoSize

                finalResult.screenshootList.append(contentsOf: result.screenshootList)
                finalResult.screenshotImageSize += result.screenshotImageSize

                finalResult.videoSize += result.videoSize
            }

            // Aggregation complete — update UI all at once
            if !Task.isCancelled {
                await MainActor.run {
                    self.shortVideoList = finalResult.shortVideoList
                    self.allVideoList = finalResult.allVideoList
                    self.screenRecordingVideoList = finalResult.screenRecordingVideoList
                    self.screenshootList = finalResult.screenshootList

                    self.shortVideoSize = finalResult.shortVideoSize
                    self.allVideoSize = finalResult.allVideoSize
                    self.screenRecordingVideoSize = finalResult.screenRecordingVideoSize
                    self.screenshotImageSize = finalResult.screenshotImageSize
                    
                    // Notify delegate of data update
                    self.delegate?.mediaManager(self, didUpdateShortVideos: self.shortVideoList, totalSize: self.shortVideoSize)
                    self.delegate?.mediaManager(self, didUpdateAllVideos: self.allVideoList, totalSize: self.allVideoSize)
                    self.delegate?.mediaManager(self, didUpdateScreenRecordings: self.screenRecordingVideoList, totalSize: self.screenRecordingVideoSize)
                    self.delegate?.mediaManager(self, didUpdateScreenshots: self.screenshootList, totalSize: self.screenshotImageSize)
                }
            }
        }

        // Save cache after processing is complete
        saveCache()
    }

    // MARK: - Cache Methods

    /// Save cache data
    private nonisolated func saveCache() {
        Task { @MainActor in
            let cacheData = MediaCacheData(
                screenshotTotalSize: self.screenshotImageSize,
                latestScreenshotAssetId: self.screenshootList.first?.phAsset.localIdentifier,
                screenshotTotalCount: self.screenshootList.count,
                screenRecordingTotalSize: self.screenRecordingVideoSize,
                latestScreenRecordingAssetId: self.screenRecordingVideoList.first?.phAsset.localIdentifier,
                screenRecordingTotalCount: self.screenRecordingVideoList.count,
                allVideoTotalSize: self.allVideoSize,
                latestAllVideoAssetId: self.allVideoList.first?.phAsset.localIdentifier,
                allVideoTotalCount: self.allVideoList.count,
                shortVideoTotalSize: self.shortVideoSize,
                latestShortVideoAssetId: self.shortVideoList.first?.phAsset.localIdentifier,
                shortVideoTotalCount: self.shortVideoList.count
            )

            if let encoded = try? JSONEncoder().encode(cacheData) {
                UserDefaults.standard.set(encoded, forKey: self.cacheKey)
            }
        }
    }

    /// Load cache data
    private nonisolated func loadCache() -> MediaCacheData? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cacheData = try? JSONDecoder().decode(MediaCacheData.self, from: data)
        else {
            return nil
        }
        return cacheData
    }

    /// Restore data from cache (size info only; arrays remain empty pending background update)
    @MainActor
    private func restoreFromCache() {
        guard let cache = loadCache() else { return }
        localCache = cache
        // Restore size info for display
        screenshotImageSize = cache.screenshotTotalSize
        screenRecordingVideoSize = cache.screenRecordingTotalSize
        allVideoSize = cache.allVideoTotalSize   // Already includes recordings and short videos — do not add again
        shortVideoSize = cache.shortVideoTotalSize

        // 通知代理初始数据（仅大小，列表为空）
        delegate?.mediaManager(self, didUpdateShortVideos: [], totalSize: shortVideoSize)
        delegate?.mediaManager(self, didUpdateAllVideos: [], totalSize: allVideoSize)
        delegate?.mediaManager(self, didUpdateScreenRecordings: [], totalSize: screenRecordingVideoSize)
        delegate?.mediaManager(self, didUpdateScreenshots: [], totalSize: screenshotImageSize)
    }
}

/// MainActor-isolated helper
enum AssetDeleter {
    static func deleteAssets(identifiers: [String]) async throws -> Bool {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            PHPhotoLibrary.shared().performChanges({
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
                if fetchResult.count > 0 {
                    PHAssetChangeRequest.deleteAssets(fetchResult)
                }
            }, completionHandler: { success, _ in
                continuation.resume(returning: success)
            })
        }
    }
}
