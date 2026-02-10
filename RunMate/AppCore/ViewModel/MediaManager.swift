import AVFoundation
import Foundation
import Photos
import SwiftUI

let SHORT_VIDEO_TIME: Double = 6.0
let LARGE_VIDEO_FILE_SIZE: Int64 = 100 * 1024 * 1024

/// 缓存数据结构
struct MediaCacheData: Codable {
    // 截屏
    var screenshotTotalSize: Int64
    var latestScreenshotAssetId: String?
    var screenshotTotalCount: Int

    // 录屏
    var screenRecordingTotalSize: Int64
    var latestScreenRecordingAssetId: String?
    var screenRecordingTotalCount: Int

    var allVideoTotalSize: Int64
    var latestAllVideoAssetId: String?
    var allVideoTotalCount: Int

    // 短视频
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

/// 媒体数据更新的回调协议
protocol MediaManagerDelegate: AnyObject {
    /// 数据加载状态变化
    func mediaManager(_ manager: MediaManager, didUpdateLoadingState isLoading: Bool)
    
    /// 短视频数据更新
    func mediaManager(_ manager: MediaManager, didUpdateShortVideos videos: [MediaItemViewModel], totalSize: Int64)
    
    /// 所有视频数据更新
    func mediaManager(_ manager: MediaManager, didUpdateAllVideos videos: [MediaItemViewModel], totalSize: Int64)
    
    /// 录屏视频数据更新
    func mediaManager(_ manager: MediaManager, didUpdateScreenRecordings recordings: [MediaItemViewModel], totalSize: Int64)
    
    /// 截屏图片数据更新
    func mediaManager(_ manager: MediaManager, didUpdateScreenshots screenshots: [MediaItemViewModel], totalSize: Int64)
    
    /// 权限状态变化
    func mediaManager(_ manager: MediaManager, didUpdateAuthorizationStatus status: PHAuthorizationStatus)
    
    /// 扫描完成
    func mediaManager(_ manager: MediaManager, didFinishScanWithTime scanTime: Double)
}

// 可选的默认实现
extension MediaManagerDelegate {
    func mediaManager(_ manager: MediaManager, didUpdateLoadingState isLoading: Bool) {}
    func mediaManager(_ manager: MediaManager, didUpdateShortVideos videos: [MediaItemViewModel], totalSize: Int64) {}
    func mediaManager(_ manager: MediaManager, didUpdateAllVideos videos: [MediaItemViewModel], totalSize: Int64) {}
    func mediaManager(_ manager: MediaManager, didUpdateScreenRecordings recordings: [MediaItemViewModel], totalSize: Int64) {}
    func mediaManager(_ manager: MediaManager, didUpdateScreenshots screenshots: [MediaItemViewModel], totalSize: Int64) {}
    func mediaManager(_ manager: MediaManager, didUpdateAuthorizationStatus status: PHAuthorizationStatus) {}
    func mediaManager(_ manager: MediaManager, didFinishScanWithTime scanTime: Double) {}
}

// 移除类级别的 @MainActor
class MediaManager: NSObject, PHPhotoLibraryChangeObserver {
    // MARK: - Properties
    
    /// 短视频(时长 <= 6 秒)
    @MainActor private(set) var shortVideoList: [MediaItemViewModel] = []
    /// 视频列表
    @MainActor private(set) var allVideoList: [MediaItemViewModel] = []
    /// 录屏
    @MainActor private(set) var screenRecordingVideoList: [MediaItemViewModel] = []
    /// 截屏
    @MainActor private(set) var screenshootList: [MediaItemViewModel] = []

    /// 所有视频总大小
    @MainActor private(set) var allVideoSize: Int64 = 0
    @MainActor private(set) var shortVideoSize: Int64 = 0
    @MainActor private(set) var screenRecordingVideoSize: Int64 = 0
    @MainActor private(set) var screenshotImageSize: Int64 = 0

    @MainActor private(set) var isLoading: Bool = false {
        didSet {
            delegate?.mediaManager(self, didUpdateLoadingState: isLoading)
        }
    }

    // 这些属性不需要主线程隔离
    private(set) var localCache: MediaCacheData?
    
    // 使用 actor-safe 的方式管理 fetchTask
    private let fetchTaskLock = NSLock()
    private var _fetchTask: Task<Void, Never>?
    
    private var allAssetsFetchResult: PHFetchResult<PHAsset>?

    // 缓存键
    private let cacheKey = "AssetsLibraryCache"
    private let cachePermissionKey = "PhotoLibraryPermissionCache"

    /// 扫描统计
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

    // init 标记为 nonisolated，不在主线程执行
    nonisolated override init() {
        super.init()
        // 不在 init 中做任何耗时操作
    }
    
    // 新增：显式的初始化方法
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
                // 更新保存的 FetchResult
                self.allAssetsFetchResult = changes.fetchResultAfterChanges
                if changes.hasIncrementalChanges {
                    // 获取被删除的对象的索引
                    if let removedIndexes = changes.removedIndexes, !removedIndexes.isEmpty {
                        let removedAssets = changes.removedObjects
                        print("检测到删除: \(removedAssets.count) 个资源")

                        // 从现有列表中移除
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
        // 先加载缓存数据
        restoreFromCache()

        Task.detached(priority: .userInitiated) { [weak self] in
            // 后台静默更新
            await self?.fetchAssets()
        }
    }

    /// 外部调用，申请权限
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

    /// 删除指定的资源（从照片库和内存中删除）
    /// - Parameter assets: 要删除的 PHAsset 数组
    /// - Returns: 是否删除成功
    /// - Throws: 删除过程中的错误
    @discardableResult
    nonisolated func deleteAssets(assets: [PHAsset]) async throws -> Bool {
        guard !assets.isEmpty else { return false }
        print("开始删除 \(assets.count) 个资源")

        // 获取 identifiers
        let identifiers = assets.map { $0.localIdentifier }
        // 使用非 Actor 隔离的 Helper 执行删除
        let success = try await AssetDeleter.deleteAssets(identifiers: identifiers)

        if success {
            // 从内存中移除并更新统计
            let ids = Set(identifiers)
            await MainActor.run {
                self.removeAssets(ids: ids)
            }
        }

        return success
    }

    // MARK: - Private Methods

    /// 已有权限时注册相册变更监听
    private nonisolated func checkAuthorization() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status != .notDetermined {
            // 检查权限是否发生变化
            await checkPermissionChange(newStatus: status)
            await MainActor.run {
                self.authorizationStatus = status
            }
            await regeisterPhotoLibraryListener()
        }
    }

    /// 检查权限变化，如果变化则清空缓存
    private nonisolated func checkPermissionChange(newStatus: PHAuthorizationStatus) async {
        let cachedPermission = UserDefaults.standard.integer(forKey: cachePermissionKey)
        let newPermissionValue = newStatus.rawValue

        // 如果有缓存的权限值且与当前权限不同，清空 localCache
        if cachedPermission != 0, cachedPermission != newPermissionValue {
            print("权限状态变化: \(cachedPermission) -> \(newPermissionValue)，清空缓存")
            localCache = nil
            UserDefaults.standard.removeObject(forKey: cacheKey)
        }

        // 保存当前权限状态
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

    /// 从所有列表中移除指定 ID 的资源
    @MainActor
    private func removeAssets(ids: Set<String>) {
        // Short Video
        let shortToRemove = shortVideoList.filter { ids.contains($0.phAsset.localIdentifier) }
        if !shortToRemove.isEmpty {
            shortVideoList.removeAll { ids.contains($0.phAsset.localIdentifier) }
            let sizeToRemove = shortToRemove.reduce(0) { $0 + $1.size }
            shortVideoSize -= sizeToRemove
            
            // 通知代理
            delegate?.mediaManager(self, didUpdateShortVideos: shortVideoList, totalSize: shortVideoSize)
        }

        let allVideoToRemove = allVideoList.filter { ids.contains($0.phAsset.localIdentifier) }
        if !allVideoToRemove.isEmpty {
            allVideoList.removeAll { ids.contains($0.phAsset.localIdentifier) }
            let sizeToRemove = allVideoToRemove.reduce(0) { $0 + $1.size }
            allVideoSize -= sizeToRemove
            
            // 通知代理
            delegate?.mediaManager(self, didUpdateAllVideos: allVideoList, totalSize: allVideoSize)
        }

        let screenRecordingToRemove = screenRecordingVideoList.filter { ids.contains($0.phAsset.localIdentifier) }
        if !screenRecordingToRemove.isEmpty {
            screenRecordingVideoList.removeAll { ids.contains($0.phAsset.localIdentifier) }
            let sizeToRemove = screenRecordingToRemove.reduce(0) { $0 + $1.size }
            screenRecordingVideoSize -= sizeToRemove
            
            // 通知代理
            delegate?.mediaManager(self, didUpdateScreenRecordings: screenRecordingVideoList, totalSize: screenRecordingVideoSize)
        }

        let screenshotToRemove = screenshootList.filter { ids.contains($0.phAsset.localIdentifier) }
        if !screenshotToRemove.isEmpty {
            screenshootList.removeAll { ids.contains($0.phAsset.localIdentifier) }
            let sizeToRemove = screenshotToRemove.reduce(0) { $0 + $1.size }
            screenshotImageSize -= sizeToRemove
            
            // 通知代理
            delegate?.mediaManager(self, didUpdateScreenshots: screenshootList, totalSize: screenshotImageSize)
        }

        // 保存缓存
        saveCache()
    }

    private nonisolated func fetchAssets(isInitialLoad: Bool = true) async {
        // 使用线程安全的方式取消之前的任务
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
            guard status == .authorized || status == .limited else {
                print("无权限访问照片库")
                return
            }

            let startTime = Date()

            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
            self.allAssetsFetchResult = fetchResult

            var assets: [PHAsset] = []
            fetchResult.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }

            print("共找到 \(assets.count) 个资源，是否首次加载: \(isInitialLoad)")

            if isInitialLoad {
                // 首次加载：渐进式更新
                await self.processAssetsProgressively(assets)
            } else {
                // 相册变更：静默读取，一次性更新
                await self.processAssetsAtOnce(assets)
            }

            let endTime = Date()
            let scanTime = endTime.timeIntervalSince(startTime)
            await MainActor.run {
                self.scanTime = scanTime
            }
            print("扫描完成，耗时: \(scanTime) 秒")
            
            // 通知代理扫描完成
            await MainActor.run {
                self.delegate?.mediaManager(self, didFinishScanWithTime: scanTime)
            }
        }
        
        // 保存任务引用
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

    /// 首次加载：分批渐进式更新
    private nonisolated func processAssetsProgressively(_ assets: [PHAsset]) async {
        let batchSize = 100
        var processedCount = 0
        var isFirstBatch = true

        while processedCount < assets.count {
            if Task.isCancelled { break }

            let startIndex = processedCount
            let endIndex = min(processedCount + batchSize, assets.count)
            let batch = Array(assets[startIndex ..< endIndex])

            print("处理批次: \(startIndex)-\(endIndex)")

            // 处理当前批次
            await withTaskGroup(of: FetchResult.self) { group in
                for asset in batch {
                    if Task.isCancelled { break }
                    group.addTask {
                        await self.processAsset(asset)
                    }
                }

                // 收集当前批次的结果
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

                // 立即更新 UI（渐进式）
                if !Task.isCancelled {
                    print("批量更新 - 已处理: \(endIndex)/\(assets.count)")
                    let isFirst = isFirstBatch

                    await MainActor.run {
                        // 只在第一批时清空列表，避免白屏
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
                        
                        // 通知代理数据更新
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

        // 处理完成后保存缓存
        saveCache()
    }

    /// 相册变更：静默读取，一次性更新
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

            // 统计结束 一次性更新 UI
            if !Task.isCancelled {
                print("统计结束 一次性更新")

                await MainActor.run {
                    self.shortVideoList = finalResult.shortVideoList
                    self.allVideoList = finalResult.allVideoList
                    self.screenRecordingVideoList = finalResult.screenRecordingVideoList
                    self.screenshootList = finalResult.screenshootList

                    self.shortVideoSize = finalResult.shortVideoSize
                    self.allVideoSize = finalResult.allVideoSize
                    self.screenRecordingVideoSize = finalResult.screenRecordingVideoSize
                    self.screenshotImageSize = finalResult.screenshotImageSize
                    
                    // 通知代理数据更新
                    self.delegate?.mediaManager(self, didUpdateShortVideos: self.shortVideoList, totalSize: self.shortVideoSize)
                    self.delegate?.mediaManager(self, didUpdateAllVideos: self.allVideoList, totalSize: self.allVideoSize)
                    self.delegate?.mediaManager(self, didUpdateScreenRecordings: self.screenRecordingVideoList, totalSize: self.screenRecordingVideoSize)
                    self.delegate?.mediaManager(self, didUpdateScreenshots: self.screenshootList, totalSize: self.screenshotImageSize)
                }
            }
        }

        // 处理完成后保存缓存
        saveCache()
    }

    // MARK: - Cache Methods

    /// 保存缓存数据
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
                print("缓存已保存")
            }
        }
    }

    /// 加载缓存数据
    private nonisolated func loadCache() -> MediaCacheData? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cacheData = try? JSONDecoder().decode(MediaCacheData.self, from: data)
        else {
            print("未找到缓存数据")
            return nil
        }
        print("缓存已加载")
        return cacheData
    }

    /// 从缓存恢复数据（仅恢复大小信息，数组保持为空等待后台更新）
    @MainActor
    private func restoreFromCache() {
        guard let cache = loadCache() else { return }
        localCache = cache
        // 恢复大小信息用于显示
        screenshotImageSize = cache.screenshotTotalSize
        screenRecordingVideoSize = cache.screenRecordingTotalSize
        allVideoSize = cache.allVideoTotalSize
        shortVideoSize = cache.shortVideoTotalSize

        // 计算总视频大小
        allVideoSize = screenRecordingVideoSize + allVideoSize + shortVideoSize

        print("从缓存恢复数据 - 截屏: \(screenshotImageSize), 录屏: \(screenRecordingVideoSize), 大视频: \(allVideoSize), 短视频: \(shortVideoSize)")
        
        // 通知代理初始数据（仅大小，列表为空）
        delegate?.mediaManager(self, didUpdateShortVideos: [], totalSize: shortVideoSize)
        delegate?.mediaManager(self, didUpdateAllVideos: [], totalSize: allVideoSize)
        delegate?.mediaManager(self, didUpdateScreenRecordings: [], totalSize: screenRecordingVideoSize)
        delegate?.mediaManager(self, didUpdateScreenshots: [], totalSize: screenshotImageSize)
    }
}

/// 隔离 MainActor
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
