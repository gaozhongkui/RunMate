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
                RoundedRectangle(cornerRadius: 12)
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .blendMode(.multiply)
                    .offset(x: x, y: y)
                    .blur(radius: radius)
                    .mask(content)
            )
    }
}

extension UIView {
    func addGradientBorder(colors: [UIColor], width: CGFloat) {
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(origin: CGPoint.zero, size: bounds.size)
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)

        let shape = CAShapeLayer()
        shape.lineWidth = width
        shape.path = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = nil
        gradient.mask = shape

        layer.addSublayer(gradient)
    }
}
