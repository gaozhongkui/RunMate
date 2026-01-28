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

    private let itemWidth = ((UIScreen.main.bounds.width - 16) * 0.86) / 3

    var body: some View {
        Button(action: action) {
            VStack {
                ZStack(alignment: .bottom) {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.3))
                            .blur(radius: 8)
                    }
                    Image(item.image)
                        .resizable()
                        .frame(width: itemWidth, height: itemWidth)
                        .aspectRatio(contentMode: .fill)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                        )
                        .shadow(color: isSelected ? .purple.opacity(0.7) : .clear, radius: 5, x: 0, y: 0)
                }
                Text(item.title).font(.system(size: 14)).foregroundColor(.white).fontWeight(.bold).padding(.bottom, 10)
            }
        }
    }
}
