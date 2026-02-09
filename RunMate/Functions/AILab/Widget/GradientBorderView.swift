//
//  GradientBorderView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/2.
//

import UIKit

class GradientBorderView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()
    
    var gradientColors: [UIColor] = [.cyan, .magenta] {
        didSet { updateGradient() }
    }
    
    var borderWidth: CGFloat = 1.5 {
        didSet { setNeedsLayout() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        layer.addSublayer(gradientLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.frame = bounds
        updateGradient()
        
        // 【关键修改】：使用 insetBy，将路径向内缩进线宽的一半
        let inset = borderWidth / 2
        let insetRect = bounds.insetBy(dx: inset, dy: inset)
        
        // 重新计算圆角，保证它依然是完美的半圆
        let path = UIBezierPath(roundedRect: insetRect, cornerRadius: insetRect.height / 2)
        
        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = borderWidth
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        
        gradientLayer.mask = shapeLayer
        
        // 视图自身的圆角依然跟随高度
        layer.cornerRadius = bounds.height / 2
    }
    
    private func updateGradient() {
        gradientLayer.colors = gradientColors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5) // 左
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5) // 右
    }
}
