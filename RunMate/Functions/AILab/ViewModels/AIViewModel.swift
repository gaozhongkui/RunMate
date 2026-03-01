//
//  CreateAIViewModel.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI
import UIKit

@MainActor
@Observable
class AIViewModel {
    let imageAIStyles: [AIViewInfo] = [
        AIViewInfo(title: "DaVinci2",
                   image: "davinci_preview",
                   prompt: "Create a Renaissance-style masterpiece with classical composition, rich colors, and detailed brushwork reminiscent of Leonardo da Vinci"),

        AIViewInfo(title: "3D",
                   image: "3d_preview",
                   prompt: "Generate a high-quality 3D render with realistic lighting, depth, shadows, and volumetric details"),

        AIViewInfo(title: "Z-Image Turbo",
                   image: "turbo_preview",
                   prompt: "Fast generation mode: create vibrant, high-contrast images with bold colors and dynamic composition"),

        AIViewInfo(title: "ImagineArt",
                   image: "imagineart_preview",
                   prompt: "Artistic and creative interpretation with unique style, imaginative elements, and expressive visual storytelling"),

        AIViewInfo(title: "SeeDream",
                   image: "seedream_preview",
                   prompt: "Dreamy, surreal atmosphere with soft focus, ethereal lighting, and fantastical elements blended seamlessly"),

        AIViewInfo(title: "Realismo",
                   image: "realismo_preview",
                   prompt: "Photorealistic image with accurate details, natural lighting, true-to-life textures, and realistic proportions"),

        AIViewInfo(title: "Flux 2",
                   image: "flux_preview",
                   prompt: "High-fidelity image generation with excellent prompt adherence, sharp details, and balanced composition"),

        AIViewInfo(title: "QWEN",
                   image: "qwen_preview",
                   prompt: "AI-powered image creation with intelligent interpretation, coherent scenes, and contextual accuracy"),

        AIViewInfo(title: "WAN",
                   image: "wan_preview",
                   prompt: "Wide-angle artistic generation with panoramic perspectives, expansive scenes, and comprehensive visual narratives")
    ]

    var inputText = ""

    var selectedAIStyleID: UUID?

    func doGenerateImage() {
        PollinationsImageGenerator.shared.generateImage(
            prompt: inputText,
            onProgress: { progress in
                print("gzk \(progress)")

            },
            completion: { result in
                if case .success(let data) = result {
                    print("gzk \(self.inputText) \(data)")
                }
            }
        )
    }

    /// 为 `imageAIStyles` 中的每一项根据其 `prompt` 生成图片，并以 `image` 字段命名保存到应用的 Documents/AIStyleImages 目录。
    /// 返回已保存图片的本地 URL 列表。
    func generateAndSaveAllStyleImages(to directoryURL: URL? = nil, options: PollinationsImageGenerator.GenerationOptions = .default) async throws -> [URL] {
        let fileManager = FileManager.default
        let baseDir: URL = directoryURL ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("AIStyleImages", isDirectory: true)

        try fileManager.createDirectory(at: baseDir, withIntermediateDirectories: true)

        var savedURLs: [URL] = []

        for item in imageAIStyles {
            // 等待单张图片生成结果
            let genResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PollinationsImageGenerator.GenerationResult, Error>) in
                PollinationsImageGenerator.shared.generateImage(
                    prompt: item.prompt,
                    options: options,
                    onStateChange: nil,
                    onProgress: nil,
                    completion: { result in
                        switch result {
                        case .success(let r):
                            continuation.resume(returning: r)
                        case .failure(let e):
                            continuation.resume(throwing: e)
                        }
                    }
                )
            }

            guard let data = genResult.image.pngData() else {
                throw PollinationsImageGenerator.GenerationError.invalidImageData
            }

            let fileURL = baseDir.appendingPathComponent("\(item.image).png")
            try data.write(to: fileURL)
            savedURLs.append(fileURL)
        }

        return savedURLs
    }

    /// UI 友好的调用封装：在后台生成并在完成后回到主线程回调
    func generateAndSaveAllStyleImagesInBackground(options: PollinationsImageGenerator.GenerationOptions = .default, completion: @escaping (Result<[URL], Error>) -> Void) {
        Task {
            do {
                let urls = try await generateAndSaveAllStyleImages(options: options)
                await MainActor.run {
                    completion(.success(urls))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
}
