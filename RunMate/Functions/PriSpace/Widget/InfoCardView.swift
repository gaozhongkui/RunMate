//
//  InfoCardView.swift
//  RunMate
//

import SwiftUI

struct InfoCardView: View {
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "lock.shield.fill")
                .font(.title)
                .foregroundStyle(AppTheme.Colors.accentGradient)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("安全加密存储")
                    .font(AppTheme.Fonts.headline())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("使用AES-256加密保护您的图片")
                    .font(AppTheme.Fonts.caption())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding()
        .appCardStyle(cornerRadius: AppTheme.Radius.sm + 5)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
