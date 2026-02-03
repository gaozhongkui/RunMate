import Foundation
import UIKit

// MARK: - CivitAI 数据模型

struct CivitAIResponse: Codable {
    let items: [CivitAIImage]?
    let metadata: CivitAIMetadata?
    
    // 兼容性：如果返回格式不同
    var images: [CivitAIImage] {
        return items ?? []
    }
}

struct CivitAIMetadata: Codable {
    let totalItems: Int?
    let currentPage: Int?
    let pageSize: Int?
    let totalPages: Int?
    let nextCursor: String?
    let nextPage: String?
}

struct CivitAIImage: Codable {
    let id: Int?
    let url: String?
    let nsfw: Bool?
    let nsfwLevel: String?        // ✅ 改为 String，因为 API 返回 "None", "Soft" 等
    let width: Int?
    let height: Int?
    let hash: String?
    let type: String?              // 添加 type 字段
    let browsingLevel: Int?        // 添加 browsingLevel 字段
    let meta: CivitAIMeta?
    let username: String?
    let createdAt: String?
    let postId: Int?               // 添加 postId 字段
    let stats: CivitAIStats?
    
    enum CodingKeys: String, CodingKey {
        case id, url, nsfw, width, height, hash, meta, username, stats, type, postId
        case nsfwLevel = "nsfwLevel"
        case createdAt = "createdAt"
        case browsingLevel = "browsingLevel"
    }
}

struct CivitAIMeta: Codable {
    let prompt: String?
    let negativePrompt: String?
    let seed: Int64?               // ✅ 改为 Int64 以支持大数字
    let model: String?
    let sampler: String?
    let cfgScale: Double?
    let steps: Int?
    let size: String?              // 可能有尺寸信息
    let clipSkip: Int?             // 常见参数
    
    enum CodingKeys: String, CodingKey {
        case prompt, seed, model, sampler, steps, size
        case negativePrompt = "negativePrompt"
        case cfgScale = "cfgScale"
        case clipSkip = "clipSkip"
    }
}

struct CivitAIStats: Codable {
    let cryCount: Int?
    let laughCount: Int?
    let likeCount: Int?
    let dislikeCount: Int?
    let heartCount: Int?
    let commentCount: Int?
}

// MARK: - CivitAI Feed Observer

class CivitAIFeedObserver {
    private(set) var images: [PollinationFeedItem] = [] {
        didSet {
            DispatchQueue.main.async {
                self.onDataUpdate?(self.images)
            }
        }
    }
    
    private var task: Task<Void, Never>?
    
    // 配置参数
    private let pageSize = 20              // 每页加载数量
    private let memoryLimit = 200          // 内存中最多保留200条
    private let initialLoadCount = 50      // 初始加载数量
    private let databaseMaxCount = 1000    // 数据库最多保留1000条
    
    // 分页状态
    private var currentCursor: String?     // CivitAI 的游标分页
    private var hasMorePages = true        // 是否还有更多数据
    private var isLoadingMore = false      // 是否正在加载
    
    // 回调闭包
    var onDataUpdate: (([PollinationFeedItem]) -> Void)?
    var onNewItemsInserted: (([IndexPath]) -> Void)?  // 新数据插入顶部
    var onOldItemsAppended: (([IndexPath]) -> Void)?  // 历史数据追加底部
    
    // MARK: - 公共方法
    
    /// 开始加载数据（初始化）
    func startListening() {
        stopListening()
        
        task = Task {
            // 1. 先加载本地缓存数据
            let cachedItems = await loadLocalCache(limit: initialLoadCount)
            
            DispatchQueue.main.async {
                self.images = cachedItems
                print("📦 加载了 \(cachedItems.count) 条本地缓存数据")
            }
            
            // 2. 加载最新的网络数据
            await loadNewData()
        }
    }
    
    /// 停止加载
    func stopListening() {
        task?.cancel()
        task = nil
    }
    
    /// 刷新数据（下拉刷新）
    func refresh(completion: (() -> Void)? = nil) {
        Task {
            // 重置分页状态
            currentCursor = nil
            hasMorePages = true
            
            // 加载最新数据
            await loadNewData()
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    /// 加载更多历史数据（上滑加载更多）
    func loadMoreHistory(completion: (() -> Void)? = nil) {
        guard !isLoadingMore, hasMorePages else {
            completion?()
            return
        }
        
        isLoadingMore = true
        
        Task {
            // 优先从数据库加载
            if let oldestItem = images.last {
                let moreItems: [PollinationFeedItem]
                
                if let lastDbId = oldestItem.dbId {
                    // 使用数据库 ID 分页
                    moreItems = await PollinationDatabase.shared.fetchItemsBefore(lastId: lastDbId, limit: pageSize)
                } else {
                    // 使用时间戳分页
                    moreItems = await PollinationDatabase.shared.fetchItemsBefore(timestamp: oldestItem.timestamp, limit: pageSize)
                }
                
                if !moreItems.isEmpty {
                    // 从数据库获取到数据
                    await appendItems(moreItems)
                    
                    DispatchQueue.main.async {
                        self.isLoadingMore = false
                        completion?()
                    }
                    return
                }
            }
            
            // 数据库没有更多数据，从网络加载
            await loadMoreFromNetwork()
            
            DispatchQueue.main.async {
                self.isLoadingMore = false
                completion?()
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 从网络加载最新数据
    private func loadNewData() async {
        do {
            let response = try await fetchFromCivitAI(cursor: nil)
            
            // 转换为 PollinationFeedItem
            let newItems = response.images.compactMap { image -> PollinationFeedItem? in
                // 必须有 URL 才能创建 item
                guard let url = image.url else { return nil }
                return convertToFeedItem(image, url: url)
            }
            
            if !newItems.isEmpty {
                // 保存到数据库
                await PollinationDatabase.shared.saveItems(newItems, maxKeepCount: databaseMaxCount)
                
                // 更新游标
                currentCursor = response.metadata?.nextCursor
                
                // 去重并插入到顶部
                DispatchQueue.main.async {
                    let existingURLs = Set(self.images.map { $0.imageURL })
                    let uniqueNewItems = newItems.filter { !existingURLs.contains($0.imageURL) }
                    
                    if !uniqueNewItems.isEmpty {
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
                        
                        print("✅ 从网络加载了 \(uniqueNewItems.count) 条新数据")
                    }
                }
            }
        } catch {
            print("❌ 加载数据失败: \(error.localizedDescription)")
        }
    }
    
    /// 从网络加载更多数据
    private func loadMoreFromNetwork() async {
        guard hasMorePages else {
            print("📭 没有更多数据了")
            return
        }
        
        do {
            let response = try await fetchFromCivitAI(cursor: currentCursor)
            
            // 转换为 PollinationFeedItem
            let moreItems = response.images.compactMap { image -> PollinationFeedItem? in
                guard let url = image.url else { return nil }
                return convertToFeedItem(image, url: url)
            }
            
            if !moreItems.isEmpty {
                // 保存到数据库
                await PollinationDatabase.shared.saveItems(moreItems, maxKeepCount: databaseMaxCount)
                
                // 更新游标
                currentCursor = response.metadata?.nextCursor
                hasMorePages = response.metadata?.nextCursor != nil
                
                // 追加到底部
                await appendItems(moreItems)
                
                print("✅ 从网络加载了 \(moreItems.count) 条历史数据")
            } else {
                hasMorePages = false
                print("📭 没有更多数据了")
            }
        } catch {
            print("❌ 加载更多数据失败: \(error.localizedDescription)")
        }
    }
    
    /// 追加数据到底部
    private func appendItems(_ items: [PollinationFeedItem]) async {
        DispatchQueue.main.async {
            let startIndex = self.images.count
            self.images.append(contentsOf: items)
            
            // 生成 IndexPath
            let indexPaths = (startIndex..<self.images.count).map {
                IndexPath(row: $0, section: 0)
            }
            
            self.onOldItemsAppended?(indexPaths)
        }
    }
    
    /// 从 CivitAI API 获取数据
    private func fetchFromCivitAI(cursor: String?) async throws -> CivitAIResponse {
        var urlString = "https://civitai.com/api/v1/images?limit=\(pageSize)&sort=Newest"
        
        if let cursor = cursor {
            urlString += "&cursor=\(cursor)"
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        print("🌐 请求 URL: \(urlString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("📡 HTTP 状态码: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ 服务器错误响应: \(errorString)")
            }
            throw URLError(.badServerResponse)
        }
        
        // 打印原始 JSON 用于调试
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 原始 JSON (前 500 字符): \(String(jsonString.prefix(500)))")
        }
        
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode(CivitAIResponse.self, from: data)
        } catch {
            print("❌ JSON 解析失败: \(error)")
            
            // 尝试打印具体的解析错误
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ 缺少键: \(key.stringValue), 路径: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("❌ 类型不匹配: 期望 \(type), 路径: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("❌ 值为空: \(type), 路径: \(context.codingPath)")
                case .dataCorrupted(let context):
                    print("❌ 数据损坏: \(context.debugDescription)")
                @unknown default:
                    print("❌ 未知解析错误")
                }
            }
            
            throw error
        }
    }
    
    /// 转换 CivitAI 数据为 PollinationFeedItem
    private func convertToFeedItem(_ civitImage: CivitAIImage, url: String) -> PollinationFeedItem {
        // 将 Int64 的 seed 转换为 Int（如果超出范围则忽略）
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
            status: "end_generating", // CivitAI 返回的都是已生成的图片
            nsfw: civitImage.nsfw,
            dbId: nil,
            dbTimestamp: nil
        )
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
        }
        
        Task {
            await PollinationDatabase.shared.clearAllCache()
            print("🗑️ 已清空所有数据")
        }
        
        // 重置状态
        currentCursor = nil
        hasMorePages = true
        isLoadingMore = false
    }
    
    /// 获取当前数据总数
    func getCurrentCount() -> Int {
        return images.count
    }
    
    /// 获取数据库中的总数
    func getDatabaseCount() async -> Int {
        return await PollinationDatabase.shared.getTotalCount()
    }
    
    /// 重置分页状态（用于重新开始加载）
    func resetPagination() {
        currentCursor = nil
        hasMorePages = true
        isLoadingMore = false
    }
}

