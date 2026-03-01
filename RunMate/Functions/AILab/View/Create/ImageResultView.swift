//
//  ImageResultView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI
import Zoomable

struct ImageResultView: View {
    var backAction: () -> Void
    var confirmAction: () -> Void

    var body: some View {
        ZStack {
            AppTheme.Colors.pageGradient
                .ignoresSafeArea()
            
            // 1. 内容区：让图片带有像列表页一样的大圆角
            contentLayout()
            
            VStack {
                // 2. 顶部导航：保持统一的返回按钮风格
                headerView()
                
                Spacer()
                
                // 3. 底部操作：强化渐变按钮和保存感
                bottomLayout()
            }
        }
    }

    // MARK: - Header (统一风格)
    private func headerView() -> some View {
        HStack {
            Button(action: { backAction() }) {
                Image(systemName: "chevron.left")
                    .font(AppTheme.Fonts.headline())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.Colors.textPrimary.opacity(0.1))
                    .clipShape(Circle())
            }
            Spacer()
            Text("Art Ready")
                .font(AppTheme.Fonts.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)
            Spacer()
            Button(action: { /* Share action */ }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    // MARK: - Content (大圆角沉浸式展示)
    private func contentLayout() -> some View {
        VStack {
            Spacer()
            Image("ai_loading") // 这里替换为你生成的真实图片
                .resizable()
                .scaledToFit()
                .cornerRadius(AppTheme.Radius.xl)
                .shadow(color: AppTheme.Colors.accentEnd.opacity(0.3), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 20)
                .zoomable() // 保持你的缩放功能
            Spacer()
        }
        .padding(.vertical, 80)
    }

    // MARK: - Bottom (渐变按钮 + 模糊底座)
    private func bottomLayout() -> some View {
        VStack(spacing: 20) {
            // 保存按钮
            Button(action: {
                confirmAction()
            }) {
                HStack {
                    Image(systemName: "arrow.down.to.line.circle.fill")
                    Text("Save to Gallery")
                }
                .font(AppTheme.Fonts.headline())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(AppTheme.Colors.accentGradient)
                .cornerRadius(AppTheme.Radius.xxl - 5)
                .shadow(color: AppTheme.Colors.accentEnd.opacity(0.5), radius: 12, y: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(
            // 底部增加一个向上的黑色渐变遮罩，使图片和按钮过度自然
            LinearGradient(
                colors: [.clear, .black.opacity(0.8), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
