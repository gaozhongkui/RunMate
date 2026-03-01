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
        GeometryReader { geo in
            Button(action: action) {
                ZStack(alignment: .bottom) {
                    // 风格预览图，填满父视图
                    Image(item.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()

                    // 底部半透明遮罩 + 标题
                    VStack(alignment: .leading, spacing: 4) {
                        Spacer(minLength: 0)
                        Text(item.title)
                            .font(AppTheme.Fonts.caption(.medium))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .stroke(
                            isSelected
                                ? AppTheme.Colors.accentStart : Color.clear,
                            lineWidth: 2
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
}
