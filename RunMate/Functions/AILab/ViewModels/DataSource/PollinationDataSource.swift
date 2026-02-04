//
//  PollinationDataSource.swift
//  Pollination SSE 数据源实现
//
//  Created by Claude on 2026/2/3.
//

import Foundation

class PollinationDataSource: FeedDataSource {
    // MARK: - FeedDataSource 协议实现
    
    let name = "Pollination"
    let priority = 1  // 优先级1（较高）
    
    private(set) var isAvailable = true
    
    var onNewItems: (([PollinationFeedItem]) -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - 私有属性
    
    private var streamTask: Task<Void, Never>?
    private var tempStorage: [PollinationFeedItem] = []
    private let batchSaveSize = 10
    private var consecutiveErrors = 0
    private let maxConsecutiveErrors = 3
    
    // MARK: - 公共方法
    
    func startFetching() async throws {
        stopFetching()
        
        streamTask = Task {
            await startStreamingFeed()
        }
    }
    
    func stopFetching() {
        streamTask?.cancel()
        streamTask = nil
        
        // 保存剩余数据
        if !tempStorage.isEmpty {
            let itemsToSave = tempStorage
            Task {
                await PollinationDatabase.shared.saveItems(itemsToSave, maxKeepCount: 1000)
            }
            tempStorage.removeAll()
        }
    }
    
    func loadMore() async throws -> [PollinationFeedItem] {
        // Pollination 是实时流，没有历史分页
        return []
    }
    
    func refresh() async throws -> [PollinationFeedItem] {
        // 重新连接流
        try await startFetching()
        return []
    }
    
    // MARK: - 私有方法
    
    private func startStreamingFeed() async {
        guard let url = URL(string: "https://image.pollinations.ai/feed") else {
            isAvailable = false
            onError?(FeedDataSourceError.sourceUnavailable)
            return
        }
        
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
                throw FeedDataSourceError.networkError(underlying: URLError(.badServerResponse))
            }
            
            print("✅ [\(name)] 连接成功，开始接收数据流...")
            isAvailable = true
            consecutiveErrors = 0
            
            for try await line in bytes.lines {
                if Task.isCancelled { break }
                
                guard line.hasPrefix("data:") else { continue }
                
                let jsonString = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                guard let data = jsonString.data(using: .utf8) else { continue }
                
                do {
                    let item = try JSONDecoder().decode(PollinationFeedItem.self, from: data)
                    
                    if item.status == "end_generating" {
                        await handleNewItem(item)
                    }
                } catch {
                    // 单条解析失败不影响整体
                    continue
                }
            }
            
            print("⚠️ [\(name)] 数据流结束")
            
        } catch {
            consecutiveErrors += 1
            
            if consecutiveErrors >= maxConsecutiveErrors {
                isAvailable = false
                print("❌ [\(name)] 连续失败 \(consecutiveErrors) 次，标记为不可用")
            }
            
            onError?(FeedDataSourceError.networkError(underlying: error))
            
            if !Task.isCancelled && isAvailable {
                print("⚠️ [\(name)] 流中断，3秒后重连...")
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await startStreamingFeed()
            }
        }
    }
    
    private func handleNewItem(_ item: PollinationFeedItem) async {
        tempStorage.insert(item, at: 0)
        
        // 立即通知
        onNewItems?([item])
        
        // 批量保存
        if tempStorage.count >= batchSaveSize {
            let itemsToSave = tempStorage
            tempStorage.removeAll()
            await PollinationDatabase.shared.saveItems(itemsToSave, maxKeepCount: 1000)
        }
    }
}
