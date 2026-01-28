//
//  View+Ex.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

extension View {
    func glowBorder(gradient: LinearGradient, lineWidth: CGFloat = 2, blurRadius: CGFloat = 1) -> some View {
        modifier(GlowBorder(gradient: gradient, lineWidth: lineWidth, blurRadius: blurRadius))
    }

    func innerShadow(color: Color = .black.opacity(0.7), radius: CGFloat = 8, x: CGFloat = 0, y: CGFloat = 0) -> some View {
        modifier(InnerShadow(color: color, radius: radius, x: x, y: y))
    }
}

struct GlowBorder: ViewModifier {
    var gradient: LinearGradient
    var lineWidth: CGFloat
    var blurRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 24) // 假设这里的圆角和内容的圆角一致
                    .stroke(gradient, lineWidth: lineWidth)
                    .blur(radius: blurRadius)
            )
    }
}


struct InnerShadow: ViewModifier {
    var color: Color = .black
    var radius: CGFloat = 10
    var x: CGFloat = 0
    var y: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12) // 假设输入框的圆角是12
                    .fill(color)
                    .blendMode(.multiply) // 或者 .darken, 尝试不同模式
                    .offset(x: x, y: y)
                    .blur(radius: radius)
                    .mask(content) // 使用内容本身作为遮罩，只显示内容区域的阴影
            )
    }
}
