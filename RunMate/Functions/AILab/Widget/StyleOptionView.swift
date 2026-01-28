//
//  StyleOptionView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

struct StyleOptionView: View {
    let styleName: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.3)) // 选中时的背景光晕
                            .blur(radius: 8)
                    }
                    Image(styleName.lowercased().replacingOccurrences(of: " ", with: "_") + "_style_image") // 确保图片名称匹配
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2) // 选中时的边框
                        )
                        .shadow(color: isSelected ? .purple.opacity(0.7) : .clear, radius: 5, x: 0, y: 0) // 选中时的小阴影
                }
                Text(styleName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .purple : .gray)
            }
        }
    }
}
