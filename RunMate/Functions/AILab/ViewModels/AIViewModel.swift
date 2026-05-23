//
//  CreateAIViewModel.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI
import UIKit
import Combine

@MainActor
class AIViewModel: ObservableObject {
    let imageAIStyles: [AIViewInfo] = [
        AIViewInfo(
            title: "DaVinci2",
            image: "davinci_preview",
            prompt:
                "Create a Renaissance-style masterpiece with classical composition, rich colors, and detailed brushwork reminiscent of Leonardo da Vinci"
        ),

        AIViewInfo(
            title: "3D",
            image: "3d_preview",
            prompt:
                "Generate a high-quality 3D render with realistic lighting, depth, shadows, and volumetric details"
        ),

        AIViewInfo(
            title: "Z-Image Turbo",
            image: "turbo_preview",
            prompt:
                "Fast generation mode: create vibrant, high-contrast images with bold colors and dynamic composition"
        ),

        AIViewInfo(
            title: "ImagineArt",
            image: "imagineart_preview",
            prompt:
                "Artistic and creative interpretation with unique style, imaginative elements, and expressive visual storytelling"
        ),

        AIViewInfo(
            title: "SeeDream",
            image: "seedream_preview",
            prompt:
                "Dreamy, surreal atmosphere with soft focus, ethereal lighting, and fantastical elements blended seamlessly"
        ),
    ]

    var ratioArray = ["1:1", "4:3", "3:2", "16:9", "8:6"]

    @Published var inputText = ""
    @Published var selectedAIStyleID: UUID?
    @Published var selectRatioIndex: Int = 0

    // Generation state
    @Published var isGenerating: Bool = false
    @Published var generatedImage: UIImage? = nil
    @Published var generationError: String? = nil

    /// The title of the currently selected style (used for storing history)
    var selectedStyleTitle: String {
        imageAIStyles.first { $0.id == selectedAIStyleID }?.title ?? "AI Art"
    }

    func doGenerateImage() {
        // 1. Get the selected style
        let selectedStyle = imageAIStyles.first { $0.id == selectedAIStyleID }

        // 2. Combine prompt: user input + style prompt
        let sanitizedInput = sanitizePrompt(inputText)
        let stylePrompt = selectedStyle?.prompt ?? ""
        let fullPrompt: String
        if stylePrompt.isEmpty {
            fullPrompt = sanitizedInput
        } else if sanitizedInput.isEmpty {
            fullPrompt = stylePrompt
        } else {
            fullPrompt = "\(sanitizedInput), \(stylePrompt)"
        }

        // 3. Match the model based on the style image name
        let model: PollinationsImageGenerator.Model
        switch selectedStyle?.image {
        case "davinci_preview":  model = .gptimage
        case "turbo_preview":    model = .turbo
        case "seedream_preview": model = .seedream
        default:                 model = .flux
        }

        // 4. Convert ratio to resolution
        let ratio = ratioArray.indices.contains(selectRatioIndex) ? ratioArray[selectRatioIndex] : "1:1"
        let (width, height): (Int, Int)
        switch ratio {
        case "4:3":  (width, height) = (1024, 768)
        case "3:2":  (width, height) = (1024, 683)
        case "16:9": (width, height) = (1024, 576)
        case "8:6":  (width, height) = (1024, 768)
        default:     (width, height) = (1024, 1024) // 1:1
        }

        // 5. Build options
        var options = PollinationsImageGenerator.GenerationOptions()
        options.model = model
        options.width = width
        options.height = height

        // 6. Start generation
        isGenerating = true
        generatedImage = nil
        generationError = nil

        PollinationsImageGenerator.shared.generateImage(
            prompt: fullPrompt,
            options: options,
            onStateChange: nil,
            onProgress: nil,
            completion: { [weak self] result in
                guard let self else { return }
                self.isGenerating = false
                switch result {
                case .success(let data):
                    self.generatedImage = data.image
                case .failure(let error):
                    self.generationError = error.localizedDescription
                }
            }
        )
    }

    private func sanitizePrompt(_ prompt: String) -> String {
        var sanitized = prompt
            .replacingOccurrences(of: #"[\{\}\[\]\<\>\|\\]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)\bBREAK\b"#, with: ", ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let allowedCharacters = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: ".,:;!?()'\"-_/"))

        sanitized = String(sanitized.unicodeScalars.map { scalar in
            allowedCharacters.contains(scalar) ? Character(scalar) : " "
        })
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)

        let maxLength = 800
        if sanitized.count > maxLength {
            sanitized = String(sanitized.prefix(maxLength))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return sanitized
    }

    func cancelGeneration() {
        PollinationsImageGenerator.shared.cancelGeneration()
        isGenerating = false
    }
}
