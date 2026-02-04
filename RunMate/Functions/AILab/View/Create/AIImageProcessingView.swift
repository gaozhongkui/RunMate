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
    // 增加一个旋转动画状态，增强视觉效果
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // 背景色统一为黑色
            Color.black.ignoresSafeArea()
            
            // 装饰背景（可选：增加一点紫色的微光效果）
            Circle()
                .fill(Color(hex: "#8A2BE2").opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(y: -100)

            VStack {
                headerView()
                
                Spacer()
                
                contentView()
                    .frame(maxHeight: .infinity)
                
                Spacer()
                
                // 底部提示
                Text("Artistic creation takes time, please wait...")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            // 模拟进度动画
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                progress = 1.0
            }
            // 增加持续旋转效果
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }

    // MARK: - Header (保持风格一致)
    private func headerView() -> some View {
        HStack {
            Button(action: { backAction() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Generating Art")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // 为了视觉平衡放一个空的占位
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
    }

    // MARK: - Content (强化视觉中心)
    private func contentView() -> some View {
        VStack(spacing: 40) {
            ZStack {
                // 1. 底层光晕
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 15)
                    .frame(width: 180, height: 180)
                
                // 2. 进度圆环 (使用与首页一致的渐变色)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "#8A2BE2"), Color(hex: "#00FFFF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90)) // 从顶部开始进度
                    .rotationEffect(.degrees(rotation)) // 持续旋转感
                
                // 3. 中心图标
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .shadow(color: Color(hex: "#00FFFF").opacity(0.8), radius: 10)
            }
            
            VStack(spacing: 12) {
                Text("Creating your artwork...")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Text("The AI is painting your thoughts")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}
