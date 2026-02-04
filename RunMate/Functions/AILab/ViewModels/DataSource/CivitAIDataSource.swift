//
//  CivitAIDataSource.swift
//  CivitAI REST API 数据源实现
//
//  Created by Claude on 2026/2/3.
//

import Foundation

class CivitAIDataSource: FeedDataSource {
    // MARK: - FeedDataSource 协议实现
    
    let name = "CivitAI"
    let priority = 2  // 优先级2（较低）
    
    private(set) var isAvailable = true
    
    var onNewItems: (([PollinationFeedItem]) -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - 私有属性
    
    private var pollingTask: Task<Void, Never>?
    private var currentCursor: String?
    private var hasMorePages = true
    private let pageSize = 20
    private let pollingInterval: TimeInterval = 30  // 30秒轮询一次
    private var consecutiveErrors = 0
    private let maxConsecutiveErrors = 3
    
    // MARK: - 公共方法
    
    func startFetching() async throws {
        stopFetching()
        
        // 先加载一次数据
        let items = try await fetchData(cursor: nil)
        onNewItems?(items)
        
        // 开始轮询
        pollingTask = Task {
            await startPolling()
        }
    }
    
    func stopFetching() {
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    func loadMore() async throws -> [PollinationFeedItem] {
        guard hasMorePages else {
            return []
        }
        
        return try await fetchData(cursor: currentCursor)
    }
    
    func refresh() async throws -> [PollinationFeedItem] {
        currentCursor = nil
        hasMorePages = true
        return try await fetchData(cursor: nil)
    }
    
    // MARK: - 私有方法
    
    private func startPolling() async {
        while !Task.isCancelled {
            do {
                // 每次轮询获取最新数据（无游标）
                let items = try await fetchData(cursor: nil)
                
                if !items.isEmpty {
                    onNewItems?(items)
                    consecutiveErrors = 0
                    isAvailable = true
                }
                
                // 等待下次轮询
                try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
                
            } catch {
                consecutiveErrors += 1
                
                if consecutiveErrors >= maxConsecutiveErrors {
                    isAvailable = false
                    print("❌ [\(name)] 连续失败 \(consecutiveErrors) 次，标记为不可用")
                }
                
                onError?(error)
                
                // 等待后重试
                try? await Task.sleep(nanoseconds: 10_000_000_000)
            }
        }
    }
    
    private func fetchData(cursor: String?) async throws -> [PollinationFeedItem] {
        var urlString = "https://civitai.com/api/v1/images?limit=\(pageSize)&sort=Newest"
        
        if let cursor = cursor {
            urlString += "&cursor=\(cursor)"
        }
        
        guard let url = URL(string: urlString) else {
            throw FeedDataSourceError.sourceUnavailable
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FeedDataSourceError.networkError(underlying: URLError(.badServerResponse))
        }
        
        do {
            let civitResponse = try JSONDecoder().decode(CivitAIResponse.self, from: data)
            
            // 更新分页状态
            currentCursor = civitResponse.metadata?.nextCursor
            hasMorePages = civitResponse.metadata?.nextCursor != nil
            
            // 转换为统一格式
            let items = civitResponse.images.compactMap { image -> PollinationFeedItem? in
                guard let url = image.url else { return nil }
                return convertToFeedItem(image, url: url)
            }
            
            print("✅ [\(name)] 获取了 \(items.count) 条数据")
            
            // 保存到数据库
            if !items.isEmpty {
                await PollinationDatabase.shared.saveItems(items, maxKeepCount: 1000)
            }
            
            return items
            
        } catch {
            throw FeedDataSourceError.parseError(underlying: error)
        }
    }
    
    private func convertToFeedItem(_ civitImage: CivitAIImage, url: String) -> PollinationFeedItem {
        let seed: Int? = {
            guard let seedValue = civitImage.meta?.seed else { return nil }
            return Int(exactly: seedValue)
        }()
        
        return PollinationFeedItem(
            imageURL: url,
            prompt: civitImage.meta?.prompt,
            width: civitImage.width,
            height: civitImage.height,
            seed: seed,
            model: civitImage.meta?.model,
            enhance: nil,
            safe: civitImage.nsfw == false,
            nologo: nil,
            quality: nil,
            status: "end_generating",
            nsfw: civitImage.nsfw,
            dbId: nil,
            dbTimestamp: nil
        )
    }
}
