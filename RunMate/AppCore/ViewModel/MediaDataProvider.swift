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

@Observable
@MainActor
class MediaDataProvider: NSObject, PHPhotoLibraryChangeObserver {
    /// 短视频(时长 <= 6 秒)
    var shortVideoList: [MediaItemViewModel] = []
    /// 视频列表
    var allVideoList: [MediaItemViewModel] = []
    /// 录屏
    var screenRecordingVideoList: [MediaItemViewModel] = []
    /// 截屏
    var screenshootList: [MediaItemViewModel] = []

    /// 所有视频总大小
    var allVideoSize: Int64 = 0

    var shortVideoSize: Int64 = 0

    var screenRecordingVideoSize: Int64 = 0

    var screenshotImageSize: Int64 = 0

    var isLoading: Bool = false

    var localCache: MediaCacheData?

    private var fetchTask: Task<Void, Never>?
    private var allAssetsFetchResult: PHFetchResult<PHAsset>?

    // 缓存键
    private let cacheKey = "AssetsLibraryCache"
    private let cachePermissionKey = "PhotoLibraryPermissionCache"

    /// 扫描统计
    var scanTime: Double = 0.0

    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            if self.isLoading {
                await fetchAssets(isInitialLoad: false)
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
                        await fetchAssets(isInitialLoad: false)
                    }
                } else {
                    await fetchAssets(isInitialLoad: false)
                }
            } else {
                await fetchAssets(isInitialLoad: false)
            }
        }
    }

    var authorizationStatus: PHAuthorizationStatus = .notDetermined

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    override init() {
        super.init()
        checkAuthorization()
    }

    func readData() {
        // 先加载缓存数据
        restoreFromCache()

        Task {
            // 后台静默更新
            await fetchAssets()
        }
    }

    /// 外部调用，申请权限
    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            checkPermissionChange(newStatus: newStatus)
            authorizationStatus = newStatus
            regeisterPhotoLibraryListener()
        } else {
            checkPermissionChange(newStatus: status)
            authorizationStatus = status
            regeisterPhotoLibraryListener()
        }
        return authorizationStatus
    }

    /// 已有权限时注册相册变更监听
    private func checkAuthorization() {
        Task {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            if status != .notDetermined {
                // 检查权限是否发生变化
                checkPermissionChange(newStatus: status)
                authorizationStatus = status
                regeisterPhotoLibraryListener()
            }
        }
    }

    /// 检查权限变化，如果变化则清空缓存
    private func checkPermissionChange(newStatus: PHAuthorizationStatus) {
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

    private func regeisterPhotoLibraryListener() {
        if authorizationStatus == .authorized || authorizationStatus == .limited {
            PHPhotoLibrary.shared().register(self)
            readData()
        }
    }

    /// 删除指定的资源（从照片库和内存中删除）
    /// - Parameter assets: 要删除的 PHAsset 数组
    /// - Returns: 是否删除成功
    /// - Throws: 删除过程中的错误
    @discardableResult
    func deleteAssets(assets: [PHAsset]) async throws -> Bool {
        guard !assets.isEmpty else { return false }
        print("开始删除 \(assets.count) 个资源")

        // 获取 identifiers
        let identifiers = assets.map { $0.localIdentifier }
        // 使用非 Actor 隔离的 Helper 执行删除
        let success = try await AssetDeleter.deleteAssets(identifiers: identifiers)

        if success {
            // 从内存中移除并更新统计
            let ids = Set(identifiers)
            removeAssets(ids: ids)
        }

        return success
    }

    /// 从所有列表中移除指定 ID 的资源
    func removeAssets(ids: Set<String>) {
        // Short Video
        let shortToRemove = shortVideoList.filter { ids.contains($0.phAsset.localIdentifier) }
        if !shortToRemove.isEmpty {
            shortVideoList.removeAll { ids.contains($0.phAsset.localIdentifier) }
            let sizeToRemove = shortToRemove.reduce(0) { $0 + $1.size }
            shortVideoSize -= sizeToRemove
        }

        let allVideoToRemove = allVideoList.filter { ids.contains($0.phAsset.localIdentifier) }
        if !allVideoToRemove.isEmpty {
            allVideoList.removeAll { ids.contains($0.phAsset.localIdentifier) }
            let sizeToRemove = allVideoToRemove.reduce(0) { $0 + $1.size }
            allVideoSize -= sizeToRemove
        }

        // Screen Recording
        let screenToRemove = screenRecordingVideoList.filter { ids.contains($0.phAsset.localIdentifier) }
        if !screenToRemove.isEmpty {
            screenRecordingVideoList.removeAll { ids.contains($0.phAsset.localIdentifier) }
            let sizeToRemove = screenToRemove.reduce(0) { $0 + $1.size }
            screenRecordingVideoSize -= sizeToRemove
        }

        // Screenshot
        let screenshotToRemove = screenshootList.filter { ids.contains($0.phAsset.localIdentifier) }
        if !screenshotToRemove.isEmpty {
            screenshootList.removeAll { ids.contains($0.phAsset.localIdentifier) }
            let sizeToRemove = screenshotToRemove.reduce(0) { $0 + $1.size }
            screenshotImageSize -= sizeToRemove
        }

        // 更新缓存
        saveCache()
    }

    func fetchAssets(isInitialLoad: Bool = true) async {
        // 取消上一次的任务，防止数据冲突
        fetchTask?.cancel()
        let scanBeginTime = Date()
        isLoading = true

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let allAssets = PHAsset.fetchAssets(with: fetchOptions)
        allAssetsFetchResult = allAssets
        print("开始读取相册")

        // Capture hasCache before entering detached task to avoid actor isolation issues
        let localCache = self.localCache

        fetchTask = Task.detached { [weak self, isInitialLoad, localCache] in
            guard let self = self else { return }

            if Task.isCancelled { return }

            var assets: [PHAsset] = []
            allAssets.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }

            if Task.isCancelled { return }

            // 视频和截图
            let assetsToProcess = assets.filter { asset in
                let isVideo = asset.mediaType == .video
                let isScreenshot = asset.mediaType == .image && asset.mediaSubtypes.contains(.photoScreenshot)
                return isVideo || isScreenshot
            }

            print("需要处理的资源数量: \(assetsToProcess.count), 首次加载: \(isInitialLoad)")

            // 区分首次加载还是相册变动
            if isInitialLoad, localCache == nil {
                await self.processAssetsProgressively(assetsToProcess)
            } else {
                await self.processAssetsAtOnce(assetsToProcess)
            }

            print("读取相册结束")

            // 扫描完成，计算时间并通知管理器
            await MainActor.run {
                self.isLoading = false
                let nowTime = Date()
                self.scanTime = nowTime.timeIntervalSince(scanBeginTime)

                // 通知扫描统计管理器：扫描完成
                let scanResult = AssetsLibraryScanResult(
                    shortVideoCount: self.shortVideoList.count,
                    shortVideoSize: self.shortVideoSize,
                    allVideoCount: self.allVideoList.count,
                    allVideoSize: self.allVideoSize,
                    screenRecordingCount: self.screenRecordingVideoList.count,
                    screenRecordingSize: self.screenRecordingVideoSize,
                    screenshotCount: self.screenshootList.count,
                    screenshotSize: self.screenshotImageSize
                )

                /// ScanStatisticsManager.shared.notifyAssetsLibraryScanCompleted(result: scanResult)
            }
        }
    }

    /// 处理单个资源，返回 FetchResult
    @MainActor
    private func processAsset(_ asset: PHAsset) async -> FetchResult {
        if Task.isCancelled { return FetchResult() }

        guard let resource = PHAssetResource.assetResources(for: asset).first else {
            return FetchResult()
        }

        let size = Int64(resource.value(forKey: "fileSize") as? CLongLong ?? 0)
        let vm = MediaItemViewModel(phAsset: asset)

        var result = FetchResult()

        // 所有 asset
        result.allAssets.append(vm)

        switch asset.mediaType {
        case .video:
            result.allVideoList.append(vm)
            result.allVideoSize += size
            result.videoSize += size

            let duration = asset.duration

            // 短视频
            if duration <= SHORT_VIDEO_TIME {
                result.shortVideoList.append(vm)
                result.shortVideoSize += size
            }

            // 屏幕录制
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

    /// 首次加载：分批渐进式更新
    private func processAssetsProgressively(_ assets: [PHAsset]) async {
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
                            self.allVideoSize = 0
                        }

                        self.shortVideoList.append(contentsOf: batchResult.shortVideoList)
                        self.allVideoList.append(contentsOf: batchResult.allVideoList)
                        self.screenRecordingVideoList.append(contentsOf: batchResult.screenRecordingVideoList)
                        self.screenshootList.append(contentsOf: batchResult.screenshootList)

                        self.shortVideoSize += batchResult.shortVideoSize
                        self.allVideoSize += batchResult.allVideoSize
                        self.screenRecordingVideoSize += batchResult.screenRecordingVideoSize
                        self.screenshotImageSize += batchResult.screenshotImageSize
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
    private func processAssetsAtOnce(_ assets: [PHAsset]) async {
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

                    self.allVideoSize = finalResult.videoSize
                }
            }
        }

        // 处理完成后保存缓存
        saveCache()
    }

    // MARK: - Cache Methods

    /// 保存缓存数据
    private func saveCache() {
        let cacheData = MediaCacheData(
            screenshotTotalSize: screenshotImageSize,
            latestScreenshotAssetId: screenshootList.first?.phAsset.localIdentifier,
            screenshotTotalCount: screenshootList.count,
            screenRecordingTotalSize: screenRecordingVideoSize,
            latestScreenRecordingAssetId: screenRecordingVideoList.first?.phAsset.localIdentifier,
            screenRecordingTotalCount: screenRecordingVideoList.count,
            allVideoTotalSize: allVideoSize,
            latestAllVideoAssetId: allVideoList.first?.phAsset.localIdentifier,
            allVideoTotalCount: allVideoList.count,
            shortVideoTotalSize: shortVideoSize,
            latestShortVideoAssetId: shortVideoList.first?.phAsset.localIdentifier,
            shortVideoTotalCount: shortVideoList.count
        )

        if let encoded = try? JSONEncoder().encode(cacheData) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            print("缓存已保存")
        }
    }

    /// 加载缓存数据
    private func loadCache() -> MediaCacheData? {
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
