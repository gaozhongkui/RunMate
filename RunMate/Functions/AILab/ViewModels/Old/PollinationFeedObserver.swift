//
//  Untitled.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//
import Foundation

import SwiftUI

class PollinationFeedObserver {
    private(set) var images: [PollinationFeedItem] = [] {
        didSet {
            DispatchQueue.main.async {
                self.onDataUpdate?(self.images)
            }
        }
    }

    private var task: Task<Void, Never>?
    private var tempStorage: [PollinationFeedItem] = []
    
    // 配置参数
    private let batchSaveSize = 10 // 每10条保存一次
    private let memoryLimit = 200 // 内存中最多保留200条
    private let initialLoadCount = 50 // 初始加载数量
    private let databaseMaxCount = 1000 // 数据库最多保留1000条

    // 回调闭包
    var onDataUpdate: (([PollinationFeedItem]) -> Void)?
    var onNewItemsInserted: (([IndexPath]) -> Void)? // 新数据插入顶部
    var onOldItemsAppended: (([IndexPath]) -> Void)? // 历史数据追加底部
    
    // 加载状态标志
    private var isLoadingMore = false

    // MARK: - 公共方法
    
    /// 开始监听实时数据流
    func startListening() {
        stopListening()
        
        task = Task {
            // 初始加载缓存数据
            let cachedItems = await loadLocalCache(limit: initialLoadCount)
            
            DispatchQueue.main.async {
                self.images = cachedItems
                self.tempStorage = cachedItems
            }
            
            // 开始监听实时流
            await startStreamingFeed()
        }
    }

    /// 停止监听
    func stopListening() {
        task?.cancel()
        task = nil
        
        // 停止时保存剩余的缓冲数据
        if !tempStorage.isEmpty {
            let itemsToSave = tempStorage
            Task {
                await PollinationDatabase.shared.saveItems(itemsToSave, maxKeepCount: databaseMaxCount)
                print("💾 停止监听，已保存剩余 \(itemsToSave.count) 条数据")
            }
            tempStorage.removeAll()
        }
    }

    /// 加载更多历史数据（UITableView/UICollectionView 滚动到底部时调用）
    func loadMoreHistory(completion: (() -> Void)? = nil) {
        guard !isLoadingMore else {
            completion?()
            return
        }
        
        isLoadingMore = true
        
        Task {
            guard let oldestItem = images.last else {
                DispatchQueue.main.async {
                    self.isLoadingMore = false
                    completion?()
                }
                return
            }
            
            // 优先使用数据库 ID 进行精确分页
            let moreItems: [PollinationFeedItem]
            if let lastDbId = oldestItem.dbId {
                moreItems = await PollinationDatabase.shared.fetchItemsBefore(lastId: lastDbId, limit: 20)
            } else {
                // 备用方案：使用时间戳分页
                moreItems = await PollinationDatabase.shared.fetchItemsBefore(timestamp: oldestItem.timestamp, limit: 20)
            }
            
            if !moreItems.isEmpty {
                DispatchQueue.main.async {
                    let startIndex = self.images.count
                    self.images.append(contentsOf: moreItems)
                    
                    // 生成新增的 IndexPath
                    let indexPaths = (startIndex ..< self.images.count).map {
                        IndexPath(row: $0, section: 0)
                    }
                    
                    self.onOldItemsAppended?(indexPaths)
                    self.isLoadingMore = false
                    completion?()
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoadingMore = false
                    completion?()
                    print("📭 没有更多历史数据了")
                }
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 开始接收 SSE 数据流
    private func startStreamingFeed() async {
        guard let url = URL(string: "https://image.pollinations.ai/feed") else { return }  ///https://civitai.com/api/v1/images?limit=10&sort=Newest

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        let session = URLSession(configuration: config)

        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.timeoutInterval = 3600

        do {
            let (bytes, response) = try await session.bytes(for: request)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                print("❌ HTTP 状态码错误")
                return
            }
            
            print("✅ 已建立连接，开始接收实时数据流...")

            for try await line in bytes.lines {
                // 检查取消状态
                if Task.isCancelled {
                    print("⚠️ 任务已取消")
                    break
                }
                
                guard line.hasPrefix("data:") else { continue }
                
                let jsonString = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                guard let data = jsonString.data(using: .utf8) else { continue }

                do {
                    let item = try JSONDecoder().decode(PollinationFeedItem.self, from: data)
                    
                    // 过滤出生成完成的图片
                    if item.status == "end_generating" {
                        await handleNewItem(item)
                    }
                } catch {
                    // 解析单条数据失败，继续处理下一条
                    continue
                }
            }
            
            print("⚠️ 数据流结束")
            
        } catch {
            if !Task.isCancelled {
                print("⚠️ 流中断: \(error.localizedDescription)，3秒后尝试重连...")
                try? await Task.sleep(nanoseconds: 3 * 1000000000)
                
                // 自动重连
                await startStreamingFeed()
            }
        }
    }
    
    /// 处理新接收到的数据
    private func handleNewItem(_ item: PollinationFeedItem) async {
        // 检查是否已存在（根据 imageURL 去重）
        let exists = images.contains { $0.imageURL == item.imageURL }
        guard !exists else { return }
        
        // 添加到临时缓冲
        tempStorage.insert(item, at: 0)
        
        // 立即更新 UI（插入到顶部）
        DispatchQueue.main.async {
            self.images.insert(item, at: 0)
            
            // 通知 UITableView/UICollectionView 插入新行
            self.onNewItemsInserted?([IndexPath(row: 0, section: 0)])
            
            // 内存控制：超过限制时移除旧数据
            if self.images.count > self.memoryLimit {
                let removeCount = self.images.count - self.memoryLimit
                self.images.removeLast(removeCount)
                print("🧹 内存清理：移除了 \(removeCount) 条旧数据")
            }
        }
        
        // 批量保存到数据库
        if tempStorage.count >= batchSaveSize {
            let itemsToSave = tempStorage
            tempStorage.removeAll()
            
            await PollinationDatabase.shared.saveItems(itemsToSave, maxKeepCount: databaseMaxCount)
        }
    }

    /// 从数据库加载初始数据
    private func loadLocalCache(limit: Int) async -> [PollinationFeedItem] {
        return await PollinationDatabase.shared.fetchCachedItems(limit: limit)
    }
    
    // MARK: - 工具方法
    
    /// 清空所有数据（包括内存和数据库）
    func clearAll() {
        stopListening()
        
        DispatchQueue.main.async {
            self.images.removeAll()
            self.tempStorage.removeAll()
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
