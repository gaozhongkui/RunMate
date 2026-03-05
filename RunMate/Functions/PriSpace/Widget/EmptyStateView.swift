//
//  EmptyStateView.swift
//  RunMate
//
//  Shared empty state component – unified empty data display across pages
//

import SwiftUI

struct EmptyStateView: View {
    var icon: String = "tray"
    var title: String = "No Data"
    var subtitle: String?
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(AppTheme.Colors.textTertiary)

            Text(title)
                .font(AppTheme.Fonts.headline())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppTheme.Fonts.caption())
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
