//
//  AIImageProcessingView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

struct AIImageProcessingView: View {
    var backAction: () -> Void
    var processingAction: () -> Void

    @State private var progress: CGFloat = 0.0
    // Add a rotation animation state to enhance visual effect
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            AppTheme.Colors.pageGradient
                .ignoresSafeArea()
            Circle()
                .fill(Color(hex: "8A2BE2").opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(y: -100)

            VStack {
                headerView()
                
                Spacer()
                
                contentView()
                    .frame(maxHeight: .infinity)
                
                Spacer()
                
                // Bottom hint
                Text("Artistic creation takes time, please wait...")
                    .font(AppTheme.Fonts.subheadline())
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Simulate progress animation
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                progress = 1.0
            }
            // Add continuous rotation effect
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }

    // MARK: - Header (maintain consistent style)
    private func headerView() -> some View {
        HStack {
            Button(action: { backAction() }) {
                Image(systemName: "chevron.left")
                    .font(AppTheme.Fonts.headline(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.textPrimary.opacity(0.1))
                    .clipShape(Circle())
            }
            Spacer()
            Text("Generating Art")
                .font(AppTheme.Fonts.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Spacer()
            
            // Placeholder for visual balance
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
    }

    // MARK: - Content (strengthen visual focus)
    private func contentView() -> some View {
        VStack(spacing: 40) {
            ZStack {
                // 1. Base glow
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 15)
                    .frame(width: 180, height: 180)

                // 2. Progress ring (using unified theme)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AppTheme.Colors.borderGradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90)) // Start progress from the top
                    .rotationEffect(.degrees(rotation)) // Continuous rotation feel

                // 3. Center icon
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .shadow(color: Color(hex: "#00FFFF").opacity(0.8), radius: 10)
            }
            
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Creating your artwork...")
                    .font(AppTheme.Fonts.title())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("The AI is painting your thoughts")
                    .font(AppTheme.Fonts.subheadline())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
}
