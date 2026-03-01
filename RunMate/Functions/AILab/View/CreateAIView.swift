//
//  CreateAIView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

struct CreateAIView: View {
    var namespace: Namespace.ID
    @State private var viewModel: AIViewModel = .init()
    @State private var aiStep: CreateAIStep = .Config

    private let rows = [
        GridItem(.flexible(), spacing: 0.0),
        GridItem(.flexible(), spacing: 0.0),
    ]

    var body: some View {
        ZStack {
            switch aiStep {
            case .Config:
                AIImageConfigView(viewModel: $viewModel) {
                    viewModel.doGenerateImage()
                    withAnimation {
                        aiStep = .Processing
                    }
                }

            case .Processing:
                AIImageProcessingView {
                    viewModel.cancelGeneration()
                    withAnimation {
                        aiStep = .Config
                    }
                } processingAction: {
                    withAnimation {
                        aiStep = .Result
                    }
                }

            case .Result:
                ImageResultView(generatedImage: viewModel.generatedImage) {
                    withAnimation {
                        aiStep = .Config
                    }
                } confirmAction: {
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "1F1F35"), Color(hex: "121226"),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
        }
        .navigationBarBackButtonHidden()
        .onChange(of: viewModel.generatedImage) { _, image in
            if image != nil {
                withAnimation { aiStep = .Result }
            }
        }
        .onChange(of: viewModel.generationError) { _, error in
            if error != nil {
                withAnimation { aiStep = .Config }
            }
        }
    }
}
