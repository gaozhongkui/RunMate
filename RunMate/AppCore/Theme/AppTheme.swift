//
//  AppTheme.swift
//  RunMate
//
//  Unified design system - ensures consistent UI across all pages
//

import SwiftUI

// MARK: - App Theme

enum AppTheme {
    
    // MARK: - Colors
    
    enum Colors {
        /// 主背景渐变 - 左上到右下
        static let pageGradient = LinearGradient(
            colors: [Color(hex: "3A507C"), Color(hex: "21304A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 卡片背景
        static let cardBackground = Color(hex: "1A1A24")
        
        /// 卡片背景（深色变体）
        static let cardBackgroundAlt = Color(hex: "1A1629")
        
        /// 主强调渐变（紫色系）
        static let accentGradient = LinearGradient(
            colors: [Color(hex: "9D50BB"), Color(hex: "6E48AA")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 主强调色（用于按钮、选中状态）
        static let accentStart = Color(hex: "9D50BB")
        static let accentEnd = Color(hex: "6E48AA")
        
        /// 边框/装饰渐变（青紫）
        static let borderGradient = LinearGradient(
            colors: [Color(hex: "8A2BE2"), Color(hex: "00FFFF")],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        /// 主文字（浅色背景下）
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.5)
        static let textMuted = Color.gray
        
        /// Banner 深色渐变
        static let bannerGradient = LinearGradient(
            colors: [Color(white: 0.15), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 进度环/进度条
        static let progressGradient = LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 卡片描边
        static let cardStroke = LinearGradient(
            colors: [
                Color.white.opacity(0.2),
                Color.clear,
                Color.purple.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Typography
    
    enum Fonts {
        /// 大标题 (28pt)
        static func largeTitle(_ weight: Font.Weight = .bold) -> Font {
            .system(size: 28, weight: weight)
        }
        
        /// 标题 (22pt)
        static func title(_ weight: Font.Weight = .bold) -> Font {
            .system(size: 22, weight: weight)
        }
        
        /// 副标题 (18pt)
        static func headline(_ weight: Font.Weight = .bold) -> Font {
            .system(size: 18, weight: weight)
        }
        
        /// 正文 (16pt)
        static func body(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 16, weight: weight)
        }
        
        /// 小正文 (14pt)
        static func subheadline(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 14, weight: weight)
        }
        
        /// 说明文字 (13pt)
        static func caption(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 13, weight: weight)
        }
        
        /// 辅助文字 (12pt)
        static func caption2(_ weight: Font.Weight = .regular) -> Font {
            .system(size: 12, weight: weight)
        }
        
        /// 数字/等宽
        static func monospaced(size: CGFloat = 16, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight, design: .monospaced)
        }
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    
    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 35
    }
}

// MARK: - Reusable View Modifiers

struct AppCardStyle: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.Radius.md
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.Colors.cardStroke, lineWidth: 1.5)
            )
    }
}

struct AppPrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .background(AppTheme.Colors.accentGradient)
            .cornerRadius(AppTheme.Radius.lg)
    }
}

extension View {
    func appCardStyle(cornerRadius: CGFloat = AppTheme.Radius.md) -> some View {
        modifier(AppCardStyle(cornerRadius: cornerRadius))
    }
    
    func appPrimaryButtonStyle() -> some View {
        modifier(AppPrimaryButtonStyle())
    }
}
