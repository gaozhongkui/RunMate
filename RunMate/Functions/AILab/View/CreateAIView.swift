//
//  CreateAIView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

struct CreateAIView: View {
    @Environment(\.dismiss) var dismiss

    var namespace: Namespace.ID

    @State private var viewModel: AIViewModel = .init()

    private let rows = [
        GridItem(.flexible(), spacing: 9.0),
        GridItem(.flexible(), spacing: 9.0),
    ]

    var body: some View {
        VStack(spacing: 20) {
            headerView()
            ScrollView {
                contentView()
            }
            .frame(maxHeight: .infinity)

            bottomLayout()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "1F1F35"), Color(hex: "121226")]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
        }.navigationBarBackButtonHidden()
    }

    private func headerView() -> some View {
        ZStack {
            Text("AI Art Generator")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .foregroundColor(.white)
                        .padding(11)
                        .background(Color(hex: "#868095").opacity(0.2))
                        .clipShape(Circle())
                }
                .frame(width: 44, height: 44)

                Spacer()
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
    }

    private func contentView() -> some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxHeight: .infinity)

                TextEditor(text: $viewModel.inputText)
                    .frame(maxHeight: .infinity).scrollContentBackground(.hidden).padding(10).foregroundColor(.white).font(.system(size: 15))

                if viewModel.inputText.isEmpty {
                    Text("Describe the action in detail... (e.g. Running on a rainbow bridge)")
                        .foregroundColor(.white.opacity(0.2))
                        .font(.system(size: 15))
                        .padding(10)
                }
            }
            .frame(minHeight: 60)
            .glowBorder(
                gradient: LinearGradient(colors: [Color(hex: "8A2BE2"), Color(hex: "00FFFF")], startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 2,
                blurRadius: 2
            )
            .cornerRadius(12)
            .padding(.horizontal, 16)

            HStack {
                Spacer()
                AIExpandButton {
                    viewModel.inputText = AIExpandHelper.generatePaintingDescription()
                }
            }.padding(.top, 8).padding(.horizontal, 16)

            HStack {
                Text("Choose Your Sytle").font(.system(size: 18)).foregroundColor(.white).fontWeight(.bold)
                Spacer()
            }.padding(.top, 30).padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: rows) {
                    ForEach(viewModel.imageAIStyles, id: \.id) { item in
                        StyleOptionView(item: item, isSelected: item.id == viewModel.selectedAIStyleID) {
                            viewModel.selectedAIStyleID = item.id
                        }
                    }
                }.padding(.horizontal, 10)

            }.padding(.bottom, 20).padding(.top, 10)

            HStack {
                Text(" Aspect Ratio").font(.system(size: 18)).foregroundColor(.white).fontWeight(.bold)
                Spacer()
            }.padding(.top, 16).padding(.horizontal, 16)

            AspectRatioSelector().padding(.top, 10).padding(.horizontal, 16)
        }
    }

    private func bottomLayout() -> some View {
        Button(action: {
            viewModel.doGenerateImage()
        }) {
            Text("Generate")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [Color(hex: "9D50BB"), Color(hex: "6E50BB")], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(30)
                .shadow(color: Color(hex: "6E50BB").opacity(0.6), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 16)
        }
    }
}
