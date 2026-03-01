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

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.Colors.pageGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Choose Your Style")
                                .font(AppTheme.Fonts.headline())
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)

                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: 12),
                                count: 3
                            ),
                            spacing: 12
                        ) {
                            ForEach(viewModel.imageAIStyles, id: \.id) { item in
                                StyleOptionCard(
                                    item: item,
                                    isSelected: item.id
                                        == viewModel.selectedAIStyleID
                                ) {
                                    viewModel.selectedAIStyleID = item.id
                                }
                                .aspectRatio(1, contentMode: .fit)
                            }
                        }
                        .padding(.horizontal, 16)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Aspect Ratio").font(AppTheme.Fonts.headline())
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            AspectRatioSelector(
                                options: viewModel.ratioArray,
                                selectedIndex: $viewModel.selectRatioIndex
                            )
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
                        .font(AppTheme.Fonts.headline(.semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                Spacer()
                Text("AI Art Generator").font(AppTheme.Fonts.headline())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                Image(systemName: "person.circle").foregroundColor(
                    AppTheme.Colors.textPrimary
                ).font(.title3)
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

                        Text(
                            "Describe the action in detail... (e.g. Running on a rainbow bridge)"
                        )
                        .foregroundColor(.white.opacity(0.2))
                        .font(.system(size: 15))

                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .allowsHitTesting(false)
                }
            }
            .background(AppTheme.Colors.textPrimary.opacity(0.05))
            .cornerRadius(AppTheme.Radius.xl + 1)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xl + 1)
                    .stroke(AppTheme.Colors.borderGradient, lineWidth: 1.5)
            )
            .padding(.horizontal, 16)
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    private func bottomLayout() -> some View {
        VStack {
            Spacer()
            ZStack {
                Button(action: { generateAction() }) {
                    Text("Generate")
                        .font(AppTheme.Fonts.headline())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppTheme.Colors.accentGradient)
                        .cornerRadius(AppTheme.Radius.lg + 2)
                        .shadow(
                            color: AppTheme.Colors.accentEnd.opacity(0.5),
                            radius: 10,
                            y: 5
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .frame(height: 100)
        }
        .ignoresSafeArea()
    }
}
