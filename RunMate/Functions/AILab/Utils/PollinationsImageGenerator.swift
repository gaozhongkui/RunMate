//
//  PollinationsImageGenerator.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

import UIKit


class PollinationsImageGenerator {
    
    // MARK: - Enums
    
    /// 生成状态枚举
    enum GenerationState: Equatable {
        case idle              // 空闲
        case preparing         // 准备中
        case requesting        // 请求中
        case downloading(Double) // 下载中(进度)
        case processing        // 处理中
        case completed         // 完成
        case failed(String)    // 失败
        
        var isLoading: Bool {
            switch self {
            case .idle, .completed, .failed:
                return false
            default:
                return true
            }
        }
        
        var description: String {
            switch self {
            case .idle:
                return "等待开始"
            case .preparing:
                return "准备生成..."
            case .requesting:
                return "请求服务器..."
            case .downloading(let progress):
                return "下载中 \(Int(progress * 100))%"
            case .processing:
                return "处理图片..."
            case .completed:
                return "生成完成"
            case .failed(let error):
                return "失败: \(error)"
            }
        }
    }
    
    /// 模型选择
    enum Model: String, CaseIterable {
        case flux = "flux"
        case turbo = "turbo"
        case gptimage = "gptimage"
        case seedream = "seedream"
        case kontext = "kontext"
        
        var displayName: String {
            rawValue.capitalized
        }
    }
    
    /// 生成选项
    struct GenerationOptions {
        var model: Model = .flux
        var width: Int = 1024
        var height: Int = 1024
        var seed: Int? = nil
        var nologo: Bool = true
        var enhance: Bool = false
        
        static let `default` = GenerationOptions()
    }
    
    /// 生成结果
    struct GenerationResult {
        let image: UIImage
        let imageURL: URL
        let prompt: String
    }
    
    // MARK: - Callback Types
    
    /// 状态变化回调
    typealias StateChangeHandler = (GenerationState) -> Void
    
    /// 进度回调
    typealias ProgressHandler = (Double) -> Void
    
    /// 完成回调
    typealias CompletionHandler = (Result<GenerationResult, Error>) -> Void
    
    // MARK: - Private Properties
    
    private var downloadTask: URLSessionDownloadTask?
    private var stateChangeHandler: StateChangeHandler?
    private var progressHandler: ProgressHandler?
    
    // MARK: - Singleton
    static let shared = PollinationsImageGenerator()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 生成图片
    /// - Parameters:
    ///   - prompt: 描述词
    ///   - options: 生成选项
    ///   - onStateChange: 状态变化回调
    ///   - onProgress: 进度回调 (0.0 - 1.0)
    ///   - completion: 完成回调
    func generateImage(
        prompt: String,
        options: GenerationOptions = .default,
        onStateChange: StateChangeHandler? = nil,
        onProgress: ProgressHandler? = nil,
        completion: @escaping CompletionHandler
    ) {
        self.stateChangeHandler = onStateChange
        self.progressHandler = onProgress
        
        // 异步执行生成任务
        Task {
            // 准备阶段
            await updateState(.preparing)
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            do {
                // 1. 构建URL
                let url = try buildURL(prompt: prompt, options: options)
                
                await updateState(.requesting)
                print("🔗 图片URL: \(url.absoluteString)")
                
                // 2. 下载图片
                let image = try await downloadImage(from: url)
                
                // 3. 处理完成
                await updateState(.processing)
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
                
                await updateState(.completed)
                
                let result = GenerationResult(
                    image: image,
                    imageURL: url,
                    prompt: prompt
                )
                
                // 回调完成
                await MainActor.run {
                    completion(.success(result))
                }
                
                print("✅ 图片生成成功")
                
            } catch {
                let errorMsg = error.localizedDescription
                await updateState(.failed(errorMsg))
                
                await MainActor.run {
                    completion(.failure(error))
                }
                
                print("❌ 生成失败: \(error)")
            }
        }
    }
    
    /// 取消当前生成
    func cancelGeneration() {
        downloadTask?.cancel()
        Task {
            await updateState(.idle)
        }
    }
    
    // MARK: - Private Methods
    
    /// 更新状态
    private func updateState(_ state: GenerationState) async {
        await MainActor.run {
            self.stateChangeHandler?(state)
        }
    }
    
    /// 更新进度
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            self.progressHandler?(progress)
        }
    }
    
    /// 构建图片URL
    private func buildURL(
        prompt: String,
        options: GenerationOptions
    ) throws -> URL {
        // URL编码
        guard let encodedPrompt = prompt.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) else {
            throw GenerationError.invalidPrompt
        }
        
        // 构建URL组件
        var components = URLComponents(
            string: "https://image.pollinations.ai/prompt/\(encodedPrompt)"
        )!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "model", value: options.model.rawValue),
            URLQueryItem(name: "width", value: "\(options.width)"),
            URLQueryItem(name: "height", value: "\(options.height)"),
        ]
        
        if let seed = options.seed {
            queryItems.append(URLQueryItem(name: "seed", value: "\(seed)"))
        }
        
        if options.nologo {
            queryItems.append(URLQueryItem(name: "nologo", value: "true"))
        }
        
        if options.enhance {
            queryItems.append(URLQueryItem(name: "enhance", value: "true"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw GenerationError.invalidURL
        }
        
        return url
    }
    
    /// 下载图片（带进度）
    private func downloadImage(from url: URL) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            // 创建URLSession配置
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 60
            config.timeoutIntervalForResource = 120
            
            let session = URLSession(
                configuration: config,
                delegate: DownloadDelegate { [weak self] progress in
                    Task {
                        await self?.updateState(.downloading(progress))
                        await self?.updateProgress(progress)
                    }
                },
                delegateQueue: nil
            )
            
            // 创建下载任务
            downloadTask = session.downloadTask(with: url) { localURL, response, error in
                if let error = error {
                    continuation.resume(throwing: GenerationError.networkError(error))
                    return
                }
                
                // 检查HTTP状态
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode != 200 {
                        continuation.resume(
                            throwing: GenerationError.httpError(httpResponse.statusCode)
                        )
                        return
                    }
                }
                
                // 读取图片
                guard let localURL = localURL,
                      let imageData = try? Data(contentsOf: localURL),
                      let image = UIImage(data: imageData) else {
                    continuation.resume(throwing: GenerationError.invalidImageData)
                    return
                }
                
                continuation.resume(returning: image)
            }
            
            downloadTask?.resume()
        }
    }
    
    // MARK: - Error Types
    
    enum GenerationError: LocalizedError {
        case invalidPrompt
        case invalidURL
        case networkError(Error)
        case invalidImageData
        case httpError(Int)
        
        var errorDescription: String? {
            switch self {
            case .invalidPrompt:
                return "描述词无效"
            case .invalidURL:
                return "URL创建失败"
            case .networkError(let error):
                return "网络错误: \(error.localizedDescription)"
            case .invalidImageData:
                return "图片数据解析失败"
            case .httpError(let code):
                return "服务器错误: HTTP \(code)"
            }
        }
    }
}

// MARK: - URLSessionDownloadDelegate

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    private let progressHandler: (Double) -> Void
    
    init(progressHandler: @escaping (Double) -> Void) {
        self.progressHandler = progressHandler
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressHandler(progress)
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // 下载完成会在 downloadTask 的 completion handler 中处理
    }
}
