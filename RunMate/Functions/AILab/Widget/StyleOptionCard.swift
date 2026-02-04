//
//  StyleOptionView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

struct StyleOptionCard: View {
    let item: AIViewInfo
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                // 模拟图片
                Rectangle()
                    .fill(Color(white: 0.15))
                    .aspectRatio(0.85, contentMode: .fit)

                // 底部半透明遮罩文字
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(colors: [.clear, .black.opacity(0.7)],
                                   startPoint: .top,
                                   endPoint: .bottom)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 18)) // 图中的大圆角
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
    }
}
