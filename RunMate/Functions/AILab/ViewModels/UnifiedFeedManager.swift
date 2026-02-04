//
//  UnifiedFeedManager.swift
//  统一的多数据源管理器，支持自动切换和容错
//
//  Created by Claude on 2026/2/3.
//

import Foundation
import UIKit

class UnifiedFeedManager {
    // MARK: - 单例
    
    static let shared = UnifiedFeedManager()
    
    private init() {
        setupDataSources()
    }
    
    // MARK: - 属性
    
    private(set) var images: [PollinationFeedItem] = [] {
        didSet {
            DispatchQueue.main.async {
                self.onDataUpdate?(self.images)
            }
        }
    }
    
    private var dataSources: [FeedDataSource] = []
    private var activeSource: FeedDataSource?
    private var sourceHealthCheck: Task<Void, Never>?
    
    // 配置参数
    private let memoryLimit = 200
    private let initialLoadCount = 50
    private let healthCheckInterval: TimeInterval = 60 // 每分钟检查一次健康状态
    
    // 回调
    var onDataUpdate: (([PollinationFeedItem]) -> Void)?
    var onNewItemsInserted: (([IndexPath]) -> Void)?
    var onOldItemsAppended: (([IndexPath]) -> Void)?
    var onSourceChanged: ((String) -> Void)? // 数据源切换通知
    
    // MARK: - 设置数据源
    
    private func setupDataSources() {
        // 添加所有可用的数据源，按优先级排序
        dataSources = [
           // PollinationDataSource(),
            CivitAIDataSource()
        ]
        
        // 按优先级排序
        dataSources.sort { $0.priority < $1.priority }
        
        // 为每个数据源设置回调
        for source in dataSources {
            setupSourceCallbacks(source)
        }
    }
    
    private func setupSourceCallbacks(_ source: FeedDataSource) {
        // 新数据回调
        source.onNewItems = { [weak self] newItems in
            self?.handleNewItems(newItems, from: source)
        }
        
        // 错误回调
        source.onError = { [weak self] error in
            self?.handleSourceError(error, from: source)
        }
    }
    
    // MARK: - 公共方法
    
    /// 开始获取数据
    func startListening() {
        Task {
            // 1. 加载本地缓存
            let cachedItems = await loadLocalCache(limit: initialLoadCount)
            
            DispatchQueue.main.async {
                self.images = cachedItems
                print("📦 加载了 \(cachedItems.count) 条本地缓存数据")
            }
            
            // 2. 尝试启动数据源
            await startBestAvailableSource()
            
            // 3. 启动健康检查
            startHealthCheck()
        }
    }
    
    /// 停止获取数据
    func stopListening() {
        activeSource?.stopFetching()
        activeSource = nil
        
        sourceHealthCheck?.cancel()
        sourceHealthCheck = nil
    }
    
    /// 刷新数据
    func refresh(completion: (() -> Void)? = nil) {
        Task {
            do {
                if let source = activeSource {
                    let newItems = try await source.refresh()
                    
                    if !newItems.isEmpty {
                        handleNewItems(newItems, from: source)
                    }
                } else {
                    // 如果没有活跃源，尝试启动
                    await startBestAvailableSource()
                }
                
                DispatchQueue.main.async {
                    completion?()
                }
            } catch {
                print("❌ 刷新失败: \(error.localizedDescription)")
                
                // 尝试切换到其他数据源
                await switchToNextAvailableSource()
                
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
    }
    
    /// 加载更多数据
    func loadMoreHistory(completion: (() -> Void)? = nil) {
        Task {
            // 1. 先尝试从数据库加载
            if let oldestItem = images.last {
                let moreItems: [PollinationFeedItem]
                
                if let lastDbId = oldestItem.dbId {
                    moreItems = await PollinationDatabase.shared.fetchItemsBefore(lastId: lastDbId, limit: 20)
                } else {
                    moreItems = await PollinationDatabase.shared.fetchItemsBefore(timestamp: oldestItem.timestamp, limit: 20)
                }
                
                if !moreItems.isEmpty {
                    appendItems(moreItems)
                    DispatchQueue.main.async {
                        completion?()
                    }
                    return
                }
            }
            
            // 2. 数据库没有更多数据，尝试从网络加载
            do {
                if let source = activeSource {
                    let moreItems = try await source.loadMore()
                    
                    if !moreItems.isEmpty {
                        appendItems(moreItems)
                    }
                }
            } catch {
                print("❌ 加载更多失败: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    /// 手动切换数据源
    func switchToSource(named name: String) {
        Task {
            guard let newSource = dataSources.first(where: { $0.name == name }) else {
                print("❌ 找不到数据源: \(name)")
                return
            }
            
            // 停止当前源
            activeSource?.stopFetching()
            
            // 启动新源
            do {
                try await newSource.startFetching()
                activeSource = newSource
                
                print("✅ 已切换到数据源: \(name)")
                onSourceChanged?(name)
                
            } catch {
                print("❌ 切换到数据源 \(name) 失败: \(error.localizedDescription)")
                
                // 切换失败，尝试其他源
                await startBestAvailableSource()
            }
        }
    }
    
    /// 获取所有数据源状态
    func getAllSourcesStatus() -> [(name: String, isAvailable: Bool, priority: Int)] {
        return dataSources.map { ($0.name, $0.isAvailable, $0.priority) }
    }
    
    /// 获取当前活跃数据源名称
    func getActiveSourceName() -> String? {
        return activeSource?.name
    }
    
    // MARK: - 私有方法
    
    /// 启动最佳可用数据源
    private func startBestAvailableSource() async {
        for source in dataSources {
            guard source.isAvailable else {
                print("⚠️ 数据源 [\(source.name)] 不可用，跳过")
                continue
            }
            
            do {
                try await source.startFetching()
                activeSource = source
                
                print("✅ 成功启动数据源: [\(source.name)]")
                onSourceChanged?(source.name)
                return
                
            } catch {
                print("❌ 启动数据源 [\(source.name)] 失败: \(error.localizedDescription)")
                continue
            }
        }
        
        print("❌ 所有数据源均不可用")
    }
    
    /// 切换到下一个可用数据源
    private func switchToNextAvailableSource() async {
        guard let current = activeSource else {
            await startBestAvailableSource()
            return
        }
        
        // 停止当前源
        current.stopFetching()
        
        // 查找下一个可用源（排除当前源）
        for source in dataSources where source !== current && source.isAvailable {
            do {
                try await source.startFetching()
                activeSource = source
                
                print("✅ 已切换到备用数据源: [\(source.name)]")
                onSourceChanged?(source.name)
                return
                
            } catch {
                print("❌ 启动备用数据源 [\(source.name)] 失败: \(error.localizedDescription)")
                continue
            }
        }
        
        print("❌ 没有可用的备用数据源")
        activeSource = nil
    }
    
    /// 处理新数据
    private func handleNewItems(_ newItems: [PollinationFeedItem], from source: FeedDataSource) {
        guard !newItems.isEmpty else { return }
        
        DispatchQueue.main.async {
            // 去重
            let existingURLs = Set(self.images.map { $0.imageURL })
            let uniqueNewItems = newItems.filter { !existingURLs.contains($0.imageURL) }
            
            guard !uniqueNewItems.isEmpty else { return }
            
            // 插入到顶部
            self.images.insert(contentsOf: uniqueNewItems, at: 0)
            
            // 生成 IndexPath
            let indexPaths = (0..<uniqueNewItems.count).map { IndexPath(row: $0, section: 0) }
            self.onNewItemsInserted?(indexPaths)
            
            // 内存控制
            if self.images.count > self.memoryLimit {
                let removeCount = self.images.count - self.memoryLimit
                self.images.removeLast(removeCount)
                print("🧹 内存清理：移除了 \(removeCount) 条旧数据")
            }
            
            print("✅ 从 [\(source.name)] 接收了 \(uniqueNewItems.count) 条新数据")
        }
    }
    
    /// 处理数据源错误
    private func handleSourceError(_ error: Error, from source: FeedDataSource) {
        print("⚠️ 数据源 [\(source.name)] 错误: \(error.localizedDescription)")
        
        // 如果当前活跃源出错且不可用，尝试切换
        if source === activeSource, !source.isAvailable {
            Task {
                await switchToNextAvailableSource()
            }
        }
    }
    
    /// 追加数据到底部
    private func appendItems(_ items: [PollinationFeedItem]) {
        DispatchQueue.main.async {
            let startIndex = self.images.count
            self.images.append(contentsOf: items)
            
            let indexPaths = (startIndex..<self.images.count).map {
                IndexPath(row: $0, section: 0)
            }
            
            self.onOldItemsAppended?(indexPaths)
        }
    }
    
    /// 启动健康检查
    private func startHealthCheck() {
        sourceHealthCheck?.cancel()
        
        sourceHealthCheck = Task {
            while !Task.isCancelled {
                // 等待检查间隔
                try? await Task.sleep(nanoseconds: UInt64(healthCheckInterval * 1_000_000_000))
                
                // 检查当前活跃源是否健康
                if let current = activeSource, !current.isAvailable {
                    print("⚠️ 当前数据源 [\(current.name)] 不健康，尝试切换...")
                    await switchToNextAvailableSource()
                }
                
                // 如果没有活跃源，尝试启动
                if activeSource == nil {
                    print("⚠️ 没有活跃数据源，尝试启动...")
                    await startBestAvailableSource()
                }
            }
        }
    }
    
    /// 从数据库加载缓存
    private func loadLocalCache(limit: Int) async -> [PollinationFeedItem] {
        return await PollinationDatabase.shared.fetchCachedItems(limit: limit)
    }
    
    // MARK: - 工具方法
    
    /// 清空所有数据
    func clearAll() {
        stopListening()
        
        DispatchQueue.main.async {
            self.images.removeAll()
        }
        
        Task {
            await PollinationDatabase.shared.clearAllCache()
            print("🗑️ 已清空所有数据")
        }
    }
    
    /// 获取当前数据总数
    func getCurrentCount() -> Int {
        return images.count
    }
    
    /// 获取数据库中的总数
    func getDatabaseCount() async -> Int {
        return await PollinationDatabase.shared.getTotalCount()
    }
}
