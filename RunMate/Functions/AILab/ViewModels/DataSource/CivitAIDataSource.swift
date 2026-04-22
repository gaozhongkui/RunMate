//
//  CivitAIDataSource.swift
//  CivitAI REST API data source implementation
//
//  Created by Claude on 2026/2/3.
//

import Foundation

// MARK: - CivitAI Data Models

struct CivitAIResponse: Codable {
    let items: [CivitAIImage]?
    let metadata: CivitAIMetadata?

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
    let nsfwLevel: String?
    let width: Int?
    let height: Int?
    let hash: String?
    let type: String?
    let browsingLevel: Int?
    let meta: CivitAIMeta?
    let username: String?
    let createdAt: String?
    let postId: Int?
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
    let seed: Int64?
    let model: String?
    let sampler: String?
    let cfgScale: Double?
    let steps: Int?
    let size: String?
    let clipSkip: Int?

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

class CivitAIDataSource: FeedDataSource {
    // MARK: - FeedDataSource Protocol Implementation

    let name = "CivitAI"
    let priority = 2  // Priority 2 (lower)

    private(set) var isAvailable = true

    var onNewItems: (([PollinationFeedItem]) -> Void)?
    var onError: ((Error) -> Void)?

    // MARK: - Private Properties

    private var pollingTask: Task<Void, Never>?
    private var currentCursor: String?
    private var hasMorePages = true
    private let pageSize = 20
    private let pollingInterval: TimeInterval = 30  // Poll every 30 seconds
    private var consecutiveErrors = 0
    private let maxConsecutiveErrors = 3

    // MARK: - Public Methods

    func startFetching() async throws {
        stopFetching()

        // Load data once first
        let items = try await fetchData(cursor: nil)
        onNewItems?(items)

        // Start polling
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
    
    // MARK: - Private Methods

    private func startPolling() async {
        while !Task.isCancelled {
            do {
                // Fetch the latest data on each poll (no cursor)
                let items = try await fetchData(cursor: nil)

                if !items.isEmpty {
                    onNewItems?(items)
                    consecutiveErrors = 0
                    isAvailable = true
                }

                // Wait for the next poll
                try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))

            } catch {
                consecutiveErrors += 1

                if consecutiveErrors >= maxConsecutiveErrors {
                    isAvailable = false
                    print("❌ [\(name)] Failed \(consecutiveErrors) consecutive times, marked as unavailable")
                }

                onError?(error)

                // Wait before retrying
                try? await Task.sleep(nanoseconds: 10_000_000_000)
            }
        }
    }
    
    private func fetchData(cursor: String?) async throws -> [PollinationFeedItem] {
        var urlString = "\(RemoteConfigManager.shared.civitaiBaseURL)?limit=\(pageSize)&sort=Newest"
        
        if let cursor = cursor {
            urlString += "&cursor=\(cursor)"
        }
        
        guard let url = URL(string: urlString) else {
            throw FeedDataSourceError.sourceUnavailable
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        let apiKey = RemoteConfigManager.shared.civitaiApiKey
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
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
            
            // Convert to unified format
            let items = civitResponse.images.compactMap { image -> PollinationFeedItem? in
                guard let url = image.url else { return nil }
                return convertToFeedItem(image, url: url)
            }

            print("✅ [\(name)] Fetched \(items.count) records")

            // Save to database
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
