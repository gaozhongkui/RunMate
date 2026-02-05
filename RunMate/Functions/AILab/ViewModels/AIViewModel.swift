//
//  CreateAIViewModel.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

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
}
