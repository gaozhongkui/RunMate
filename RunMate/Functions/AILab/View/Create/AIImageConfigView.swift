//
//  AIImageConfigView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

struct AIImageConfigView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var viewModel: AIViewModel
    var generateAction: () -> Void

    // 对应图中两列布局
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#3A507C"), Color(hex: "#21304A")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                headerView()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Choose Your Sytle").font(.system(size: 18)).foregroundColor(.white).fontWeight(.bold)
                            Spacer()
                        }.padding(.horizontal, 16)
                        // 2. 瀑布流/网格内容
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(viewModel.imageAIStyles, id: \.id) { item in
                                StyleOptionCard(item: item, isSelected: item.id == viewModel.selectedAIStyleID) {
                                    viewModel.selectedAIStyleID = item.id
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // 3. 比例选择（放在滚动视图中）
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Aspect Ratio")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)

                            AspectRatioSelector()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 120)
                    }
                    .padding(.top, 10)
                }
            }

            bottomLayout()
        }
    }

    private func headerView() -> some View {
        VStack(spacing: 15) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("AI Art Generator").font(.headline).foregroundColor(.white)
                Spacer()
                Image(systemName: "person.circle").foregroundColor(.white).font(.title3)
            }
            .padding(.horizontal, 16)

            ZStack(alignment: .leading) {
                TextEditor(text: $viewModel.inputText)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 16)
                    .foregroundColor(.white)
                    .font(.system(size: 15))
                    .frame(minHeight: 50, maxHeight: 200)
                    .fixedSize(horizontal: false, vertical: true)

                if viewModel.inputText.isEmpty {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.white)
                            .padding(.leading, 10)

                        Text("Describe the action in detail... (e.g. Running on a rainbow bridge)")
                            .foregroundColor(.white.opacity(0.2))
                            .font(.system(size: 15))

                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .allowsHitTesting(false)
                }
            }
            .background(Color.white.opacity(0.05))
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(
                        LinearGradient(colors: [Color(hex: "#8A2BE2"), Color(hex: "#00FFFF")],
                                       startPoint: .leading,
                                       endPoint: .trailing),
                        lineWidth: 1.5
                    )
            )
            .padding(.horizontal, 16)
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    private func bottomLayout() -> some View {
        VStack {
            Spacer()
            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                .frame(height: 60)
                .allowsHitTesting(false)

            ZStack {
                Color.black.opacity(0.8) // 按钮区域背景

                Button(action: { generateAction() }) {
                    Text("Generate")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(colors: [Color(hex: "#C260F5"), Color(hex: "#6034E4")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                .cornerRadius(22)
                        )
                        .shadow(color: Color(hex: "6E50BB").opacity(0.5), radius: 10, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .frame(height: 100)
        }
        .ignoresSafeArea()
    }
}
