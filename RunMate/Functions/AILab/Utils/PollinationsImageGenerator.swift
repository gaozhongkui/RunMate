//
//  PollinationsImageGenerator.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//  Optimized for OpenRouter Image Generation API on 2026/05/22.
//

import SwiftUI
import UIKit

class PollinationsImageGenerator {

    // MARK: - Generation State

    enum GenerationState: Equatable {
        case idle
        case preparing
        case requesting
        case downloading(Double)
        case processing
        case completed
        case failed(String)

        var isLoading: Bool {
            switch self {
            case .idle, .completed, .failed: return false
            default: return true
            }
        }

        var description: String {
            switch self {
            case .idle: return "Ready"
            case .preparing: return "Preparing..."
            case .requesting: return "Requesting server..."
            case .downloading(let p): return "Downloading \(Int(p * 100))%"
            case .processing: return "Processing image..."
            case .completed: return "Done"
            case .failed(let e): return "Failed: \(e)"
            }
        }
    }

    // MARK: - Pollinations Models

    enum Model: String, CaseIterable {
        case flux = "flux"
        case turbo = "turbo"
        case gptimage = "gptimage"
        case seedream = "seedream"
        case kontext = "kontext"

        var displayName: String { rawValue.capitalized }
    }

    // MARK: - HuggingFace Models

    enum HuggingFaceModel: String, CaseIterable {
        case fluxSchnell = "black-forest-labs/FLUX.1-schnell"
        case sdxl = "stabilityai/stable-diffusion-xl-base-1.0"
        case sdTurbo = "stabilityai/sd-turbo"

        var displayName: String {
            switch self {
            case .fluxSchnell: return "FLUX Schnell (HF)"
            case .sdxl:        return "SDXL (HF)"
            case .sdTurbo:     return "SD Turbo (HF)"
            }
        }
    }

    // MARK: - Image Provider

    enum ImageProvider: Hashable, CustomStringConvertible {
        case pollinations(Model)
        case huggingFace(HuggingFaceModel)
        case openRouter

        var description: String {
            switch self {
            case .pollinations(let m): return "Pollinations(\(m.displayName))"
            case .huggingFace(let m):  return "HuggingFace(\(m.displayName))"
            case .openRouter:          return "OpenRouter(\(RemoteConfigManager.shared.openRouterImageModel))"
            }
        }
    }

    // MARK: - Generation Options

    struct GenerationOptions {
        var model: Model = .flux
        var width: Int = 1024
        var height: Int = 1024
        var seed: Int? = nil
        var nologo: Bool = true
        var enhance: Bool = false
        /// Optional HuggingFace token; providing it grants higher rate limits (free accounts can apply)
        var huggingFaceToken: String? = nil
        /// Optional OpenRouter token; falls back to Remote Config when unset
        var openRouterApiKey: String? = nil

        static let `default` = GenerationOptions()

        /// Automatically generates the provider priority chain based on the selected model:
        /// Tries the specified Pollinations model first, then the remaining models in order,
        /// OpenRouter when configured, and HuggingFace as the final fallback.
        var providerChain: [ImageProvider] {
            var chain: [ImageProvider] = [.pollinations(model)]
            for m in Model.allCases where m != model {
                chain.append(.pollinations(m))
            }
            let openRouterKey = openRouterApiKey ?? RemoteConfigManager.shared.openRouterApiKey
            if !openRouterKey.isEmpty, !RemoteConfigManager.shared.openRouterImageModel.isEmpty {
                chain.append(.openRouter)
            }
            for m in HuggingFaceModel.allCases {
                chain.append(.huggingFace(m))
            }
            return chain
        }
    }

    // MARK: - Generation Result

    struct GenerationResult {
        let image: UIImage
        let imageURL: URL?       // Pollinations / OpenRouter may provide a URL; HuggingFace returns nil
        let prompt: String
        let usedProvider: ImageProvider
    }

    // MARK: - Callback Types

    typealias StateChangeHandler = (GenerationState) -> Void
    typealias ProgressHandler = (Double) -> Void
    typealias CompletionHandler = (Result<GenerationResult, Error>) -> Void

    // MARK: - Provider Cooldown Tracking

    /// Cooldown duration (in seconds) after a failure; the provider is skipped during this period
    private let cooldownDuration: TimeInterval = 5 * 60
    private var providerCooldowns: [ImageProvider: Date] = [:]

    // MARK: - Private Properties

    private var downloadTask: URLSessionDownloadTask?
    private var stateChangeHandler: StateChangeHandler?
    private var progressHandler: ProgressHandler?

    // MARK: - Singleton

    static let shared = PollinationsImageGenerator()
    private init() {}

    // MARK: - Public API

    /// Generate an image, automatically trying each provider in the chain and switching when quota is exhausted
    func generateImage(
        prompt: String,
        options: GenerationOptions = .default,
        onStateChange: StateChangeHandler? = nil,
        onProgress: ProgressHandler? = nil,
        completion: @escaping CompletionHandler
    ) {
        self.stateChangeHandler = onStateChange
        self.progressHandler = onProgress

        Task {
            await updateState(.preparing)
            try? await Task.sleep(nanoseconds: 500_000_000)

            let chain = options.providerChain.filter { isAvailable($0) }
            var lastError: Error = GenerationError.allProvidersFailed

            for provider in chain {
                do {
                    await updateState(.requesting)
                    let (image, url) = try await generate(
                        prompt: prompt,
                        provider: provider,
                        options: options
                    )

                    await updateState(.processing)
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await updateState(.completed)

                    let result = GenerationResult(
                        image: image,
                        imageURL: url,
                        prompt: prompt,
                        usedProvider: provider
                    )
                    await MainActor.run { completion(.success(result)) }
                    return

                } catch {
                    lastError = error
                    if shouldMarkCooldown(for: error) {
                        markCooldown(provider)
                        print("[ImageGenerator] Provider \(provider) throttled, switching next.")
                    } else {
                        // Non-quota errors (e.g. network, image parsing) also fall through to the next provider
                        print("[ImageGenerator] Provider \(provider) failed: \(error.localizedDescription)")
                    }
                }
            }

            await updateState(.failed(lastError.localizedDescription))
            await MainActor.run { completion(.failure(lastError)) }
        }
    }

    /// Cancel the current generation task
    func cancelGeneration() {
        downloadTask?.cancel()
        Task { await updateState(.idle) }
    }

    // MARK: - Provider Availability

    private func isAvailable(_ provider: ImageProvider) -> Bool {
        guard let cooldownEnd = providerCooldowns[provider] else { return true }
        return Date() > cooldownEnd
    }

    private func markCooldown(_ provider: ImageProvider) {
        providerCooldowns[provider] = Date().addingTimeInterval(cooldownDuration)
    }

    /// Determine whether the error should trigger a provider switch (quota exceeded / service unavailable)
    private func shouldMarkCooldown(for error: Error) -> Bool {
        if let e = error as? GenerationError, case .httpError(let code) = e {
            return code == 400 || code == 429 || code == 503 || (code >= 500 && code < 600)
        }
        return false
    }

    // MARK: - Generation Dispatch

    private func generate(
        prompt: String,
        provider: ImageProvider,
        options: GenerationOptions
    ) async throws -> (UIImage, URL?) {
        switch provider {
        case .pollinations(let model):
            let url = try buildPollinationsURL(prompt: prompt, model: model, options: options)
            let image = try await downloadImage(from: url)
            return (image, url)

        case .huggingFace(let model):
            let image = try await generateWithHuggingFace(
                prompt: prompt,
                model: model,
                options: options
            )
            return (image, nil)

        case .openRouter:
            return try await generateWithOpenRouter(
                prompt: prompt,
                options: options
            )
        }
    }

    // MARK: - Pollinations

    private func buildPollinationsURL(
        prompt: String,
        model: Model,
        options: GenerationOptions
    ) throws -> URL {
        guard let encodedPrompt = prompt.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) else {
            throw GenerationError.invalidPrompt
        }

        var components = URLComponents(
            string: "\(RemoteConfigManager.shared.pollinationsBaseURL)/\(encodedPrompt)"
        )!

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "model",  value: model.rawValue),
            URLQueryItem(name: "width",  value: "\(options.width)"),
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
        let apiKey = RemoteConfigManager.shared.pollinationsApiKey
        if !apiKey.isEmpty {
            queryItems.append(URLQueryItem(name: "key", value: apiKey))
        }

        components.queryItems = queryItems
        guard let url = components.url else { throw GenerationError.invalidURL }
        return url
    }

    // MARK: - HuggingFace Inference API

    private func generateWithHuggingFace(
        prompt: String,
        model: HuggingFaceModel,
        options: GenerationOptions
    ) async throws -> UIImage {
        let endpoint = "\(RemoteConfigManager.shared.huggingFaceBaseURL)/\(model.rawValue)"
        guard let url = URL(string: endpoint) else { throw GenerationError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let effectiveToken = options.huggingFaceToken
            ?? (RemoteConfigManager.shared.huggingFaceToken.isEmpty ? nil : RemoteConfigManager.shared.huggingFaceToken)
        if let token = effectiveToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "inputs": prompt,
            "parameters": [
                "width": options.width,
                "height": options.height,
                "num_inference_steps": model == .fluxSchnell ? 4 : 20,
            ],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180

        let (data, response) = try await URLSession(configuration: config).data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw GenerationError.httpError(http.statusCode)
        }

        guard let image = UIImage(data: data) else {
            throw GenerationError.invalidImageData
        }
        return image
    }

    // MARK: - OpenRouter Image Generation (Fixed 404 & Response Schema)

    private func generateWithOpenRouter(
        prompt: String,
        options: GenerationOptions
    ) async throws -> (UIImage, URL?) {
        
        // 修正 1：动态规避 /chat/completions 路由干扰，强行指向生图专属 Endpoint
        var baseStr = RemoteConfigManager.shared.openRouterBaseURL
        if baseStr.hasSuffix("/chat/completions") {
            baseStr = baseStr.replacingOccurrences(of: "/chat/completions", with: "")
        }
        let endpoint = baseStr.hasSuffix("/") ? "\(baseStr)images/generations" : "\(baseStr)/images/generations"
        
        guard let url = URL(string: endpoint) else {
            throw GenerationError.invalidURL
        }

        let apiKey = options.openRouterApiKey ?? RemoteConfigManager.shared.openRouterApiKey
        guard !apiKey.isEmpty else {
            throw GenerationError.missingAPIKey
        }

        // 修正 2：改用顶级参数 "prompt"、将 modalities 净化为仅有 ["image"]
        let body: [String: Any] = [
            "model": RemoteConfigManager.shared.openRouterImageModel,
            "prompt": prompt,
            "modalities": ["image"],
            "image_config": [
                "aspect_ratio": openRouterAspectRatio(width: options.width, height: options.height),
            ],
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("RunMate", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180

        let (data, response) = try await URLSession(configuration: config).data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            print("[OpenRouter Error] HTTP Status Code: \(http.statusCode)")
            throw GenerationError.httpError(http.statusCode)
        }

        // 修正 3：重新编排兼容生图接口返回模式的解析链
        guard let dataString = extractOpenRouterImageDataURL(from: data) else {
            throw GenerationError.invalidImageData
        }
        
        // 判断返回的是 CDN 图像网址还是纯 Base64
        if dataString.hasPrefix("http://") || dataString.hasPrefix("https://") {
            if let remoteURL = URL(string: dataString) {
                let image = try await downloadImageWithoutDelegate(from: remoteURL)
                return (image, remoteURL)
            }
        }
        
        if let imageData = decodeDataURL(dataString), let image = UIImage(data: imageData) {
            return (image, nil)
        }

        throw GenerationError.invalidImageData
    }

    private func extractOpenRouterImageDataURL(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // 优先分支 A：标准的 /images/generations 返回规范，数据存放在顶级 "data" 节点数组中
        if let dataArray = json["data"] as? [[String: Any]] {
            for item in dataArray {
                if let url = item["url"] as? String { return url }
                if let b64 = item["b64_json"] as? String { return b64 }
            }
        }

        // 兜底分支 B：原有的混合多模态聊天结构
        if let choices = json["choices"] as? [[String: Any]] {
            for choice in choices {
                if let message = choice["message"] as? [String: Any],
                   let images = message["images"] as? [[String: Any]] {
                    for image in images {
                        if let imageURL = image["image_url"] as? [String: Any], let url = imageURL["url"] as? String { return url }
                        if let imageURL = image["imageUrl"] as? [String: Any], let url = imageURL["url"] as? String { return url }
                    }
                }
            }
        }

        return nil
    }

    private func decodeDataURL(_ dataURL: String) -> Data? {
        if dataURL.hasPrefix("data:"),
           let commaIndex = dataURL.firstIndex(of: ",")
        {
            let base64 = String(dataURL[dataURL.index(after: commaIndex)...])
            return Data(base64Encoded: base64)
        }

        return Data(base64Encoded: dataURL)
    }

    private func openRouterAspectRatio(width: Int, height: Int) -> String {
        let ratio = Double(width) / Double(height)
        let supported: [(String, Double)] = [
            ("16:9", 16.0 / 9.0),
            ("3:2", 3.0 / 2.0),
            ("4:3", 4.0 / 3.0),
            ("1:1", 1.0),
            ("3:4", 3.0 / 4.0),
            ("2:3", 2.0 / 3.0),
            ("9:16", 9.0 / 16.0),
        ]

        return supported
            .min { abs($0.1 - ratio) < abs($1.1 - ratio) }?
            .0 ?? "1:1"
    }

    // MARK: - Download Helpers

    /// Pollinations uses this to update progress bars
    private func downloadImage(from url: URL) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
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

            downloadTask = session.downloadTask(with: url) { localURL, response, error in
                if let error = error {
                    continuation.resume(throwing: GenerationError.networkError(error))
                    return
                }
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    continuation.resume(throwing: GenerationError.httpError(http.statusCode))
                    return
                }
                guard
                    let localURL = localURL,
                    let data = try? Data(contentsOf: localURL),
                    let image = UIImage(data: data)
                else {
                    continuation.resume(throwing: GenerationError.invalidImageData)
                    return
                }
                continuation.resume(returning: image)
            }
            downloadTask?.resume()
        }
    }

    /// Internal helper to pull images from OpenRouter's external image CDN URLs asynchronously
    private func downloadImageWithoutDelegate(from url: URL) async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw GenerationError.httpError(http.statusCode)
        }
        guard let image = UIImage(data: data) else {
            throw GenerationError.invalidImageData
        }
        return image
    }

    // MARK: - State / Progress Helpers

    private func updateState(_ state: GenerationState) async {
        await MainActor.run { self.stateChangeHandler?(state) }
    }

    private func updateProgress(_ progress: Double) async {
        await MainActor.run { self.progressHandler?(progress) }
    }

    // MARK: - Error Types

    enum GenerationError: LocalizedError {
        case invalidPrompt
        case invalidURL
        case networkError(Error)
        case invalidImageData
        case httpError(Int)
        case missingAPIKey
        case allProvidersFailed

        var errorDescription: String? {
            switch self {
            case .invalidPrompt:       return "Invalid prompt"
            case .invalidURL:          return "Failed to build URL"
            case .networkError(let e): return "Network error: \(e.localizedDescription)"
            case .invalidImageData:    return "Failed to parse image data"
            case .httpError(let code): return "Server error: HTTP \(code)"
            case .missingAPIKey:        return "Missing API key"
            case .allProvidersFailed:  return "All image providers failed, please try again later"
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
    ) {}
}
