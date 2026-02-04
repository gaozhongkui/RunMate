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
                    withAnimation {
                        aiStep = .Processing
                    }
                }

            case .Processing:
                AIImageProcessingView {
                    aiStep = .Config
                } processingAction: {
                    aiStep = .Result
                }

            case .Result:
                ImageResultView {
                    
                } confirmAction: {}
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "1F1F35"), Color(hex: "121226")]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
        }.navigationBarBackButtonHidden()
    }
}
