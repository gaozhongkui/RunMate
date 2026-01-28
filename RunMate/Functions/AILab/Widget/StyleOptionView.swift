//
//  StyleOptionView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

struct StyleOptionView: View {
    let item: AIViewInfo
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.3)) // 选中时的背景光晕
                            .blur(radius: 8)
                    }
                    Image(item.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                        )
                        .shadow(color: isSelected ? .purple.opacity(0.7) : .clear, radius: 5, x: 0, y: 0)

                    RoundedRectangle(cornerRadius: 20).fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.black.opacity(0.0), location: 0.0),
                                .init(color: Color.black.opacity(0.8), location: 0.8)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    ).frame(height: geo.size.height * 0.8)
                    VStack {
                        Spacer()
                        Text(item.title).font(.system(size: 16)).foregroundColor(.white).fontWeight(.bold).padding(.bottom, 10)
                    }
                }
            }
        }
    }
}
