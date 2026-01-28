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
        AIViewInfo(title: "DaVinci2", image: "ai_test", prompt: "ai_test"),
        AIViewInfo(title: "3D", image: "ai_test", prompt: "ai_test"),
        AIViewInfo(title: "Z-Image Turbo", image: "ai_test", prompt: "ai_test"),
        AIViewInfo(title: "ImagineArt", image: "ai_test", prompt: "ai_test"),
        AIViewInfo(title: "SeeDream", image: "ai_test", prompt: "ai_test"),
        AIViewInfo(title: "Realismo", image: "ai_test", prompt: "ai_test"),
        AIViewInfo(title: "Flux 2", image: "ai_test", prompt: "ai_test"),
        AIViewInfo(title: "QWEN", image: "ai_test", prompt: "ai_test"),
        AIViewInfo(title: "WAN", image: "ai_test", prompt: "ai_test")
    ]

    var selectedAIStyleID: UUID?
}
