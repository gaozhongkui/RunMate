//
//  PollinationsImageGenerator.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
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

        var description: String {
            switch self {
            case .pollinations(let m): return "Pollinations(\(m.displayName))"
            case .huggingFace(let m):  return "HuggingFace(\(m.displayName))"
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

        static let `default` = GenerationOptions()

        /// Automatically generates the provider priority chain based on the selected model:
        /// Tries the specified Pollinations model first, then the remaining models in order, with HuggingFace as the final fallback
        var providerChain: [ImageProvider] {
            var chain: [ImageProvider] = [.pollinations(model)]
            for m in Model.allCases where m != model {
                chain.append(.pollinations(m))
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
        let imageURL: URL?       // Pollinations provides a URL; HuggingFace returns nil
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
            return code == 429 || code == 503 || (code >= 500 && code < 600)
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

    /// Generate an image using the HuggingFace Inference API
    /// - Without a token it can be used for free but with lower rate limits; providing a free account token increases the rate limit
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

        // Prefer the token passed by the caller; fall back to the one from Remote Config
        let effectiveToken = options.huggingFaceToken
            ?? (RemoteConfigManager.shared.huggingFaceToken.isEmpty ? nil : RemoteConfigManager.shared.huggingFaceToken)
        if let token = effectiveToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Build request body, width/height adapted to HF parameter format
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
            // 503 means the model is cold-starting (loading); treat it as quota exhaustion to trigger a switch
            throw GenerationError.httpError(http.statusCode)
        }

        guard let image = UIImage(data: data) else {
            throw GenerationError.invalidImageData
        }
        return image
    }

    // MARK: - Download with Progress (Pollinations)

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
        case allProvidersFailed

        var errorDescription: String? {
            switch self {
            case .invalidPrompt:       return "Invalid prompt"
            case .invalidURL:          return "Failed to build URL"
            case .networkError(let e): return "Network error: \(e.localizedDescription)"
            case .invalidImageData:    return "Failed to parse image data"
            case .httpError(let code): return "Server error: HTTP \(code)"
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
