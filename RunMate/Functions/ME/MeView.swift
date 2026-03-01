//
//  MeView.swift
//  RunMate
//

import SwiftUI

struct MeView: View {
    let namespace: Namespace.ID

    var body: some View {
        ZStack {
            AppTheme.Colors.pageGradient
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.xl) {
                // 占位头像
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                
                Text("Me")
                    .font(AppTheme.Fonts.largeTitle())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text("个人中心开发中...")
                    .font(AppTheme.Fonts.caption())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
