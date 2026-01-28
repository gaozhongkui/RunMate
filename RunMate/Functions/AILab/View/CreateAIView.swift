//
//  CreateAIView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

struct CreateAIView: View {
    @Environment(\.dismiss) var dismiss

    @State private var text = ""

    @State private var selectedStyle: String = "Anime"

    let styles = ["Anime", "3D", "Cyberpunk", "Cinematic"]
    let styleImages: [String: String] = [
        "Anime": "anime_style_image",
        "3D": "3d_style_image",
        "Cyberpunk": "cyberpunk_style_image",
        "Cinematic": "cinematic_style_image"
    ]

    var body: some View {
        VStack(spacing: 20) {
            headerView()
            contentView()

        }.background {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "1F1F35"), Color(hex: "121226")]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
        }
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
                        .frame(width: 22, height: 22)
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
        ZStack {
            VStack(spacing: 20) {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(maxHeight: .infinity)

                    TextEditor(text: $text)
                        .frame(maxHeight: .infinity).scrollContentBackground(.hidden).padding(10)

                    if text.isEmpty {
                        Text("Describe the action in detail... (e.g. Running on a rainbow bridge)")
                            .foregroundColor(.gray)
                            .padding(10)
                    }
                }
                .frame(height: 200)
                .glowBorder(
                    gradient: LinearGradient(colors: [Color(hex: "8A2BE2"), Color(hex: "00FFFF")], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 2,
                    blurRadius: 2
                )
                .cornerRadius(24)
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(styles, id: \.self) { style in
                            StyleOptionView(styleName: style, isSelected: selectedStyle == style) {
                                selectedStyle = style
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                Button(action: {
                    print("Generate image with description:")
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
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    CreateAIView()
}
