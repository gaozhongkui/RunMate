//
//  AdvancedScanningCard.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/9.
//

import SwiftUI

struct AdvancedScanningCard: View {
    @State private var isAnimating = false
    @State private var dragOffset = CGSize.zero
    @Binding var viewModel: HomeViewModel

    var body: some View {
        VStack {
            if viewModel.isScanning {
                // --- 扫描状态：原始的大卡片布局 ---
                scanningLayout
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            } else {
                // --- 完成状态：紧凑的小条布局 ---
                completedCompactLayout
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .frame(maxWidth: .infinity)
        // 关键：动态调整内边距，完成状态下更窄
        .padding(.vertical, !viewModel.isScanning ? 16 : 40)
        .padding(.horizontal, 20)
        .background(cardBackground)
        // 保持 3D 效果
        .rotation3DEffect(.degrees(Double(dragOffset.width / 12)), axis: (x: 0, y: 1, z: 0))
        .rotation3DEffect(.degrees(Double(-dragOffset.height / 12)), axis: (x: 1, y: 0, z: 0))
        .gesture(
            DragGesture()
                .onChanged { value in dragOffset = value.translation }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        dragOffset = .zero
                    }
                }
        )
        .padding(.horizontal)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }

    // MARK: - 扫描中的布局 (抽取原代码)

    private var scanningLayout: some View {
        VStack(spacing: 28) {
            // ... 这里放你原来的 ZStack 进度环代码 ...
            progressRingSection

            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                        .shadow(color: .green, radius: isAnimating ? 4 : 0)
                    Text("AI Scanning...").font(AppTheme.Fonts.headline()).foregroundColor(AppTheme.Colors.textPrimary)
                }
                statusLabels
            }
        }
    }

    // MARK: - 完成后的紧凑小条布局

    private var completedCompactLayout: some View {
        HStack {
            // 左侧状态
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 18))

                Text("Scan Completed")
                    .font(AppTheme.Fonts.subheadline(.medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()

            // 右侧总大小
            HStack(spacing: 4) {
                Text("Total:")
                    .font(AppTheme.Fonts.caption())
                    .foregroundColor(AppTheme.Colors.textMuted)
                Text(viewModel.scannedSize)
                    .font(AppTheme.Fonts.monospaced())
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.08)))
        }
    }

    // MARK: - 通用背景

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: !viewModel.isScanning ? AppTheme.Radius.lg : AppTheme.Radius.xxl)
                .fill(AppTheme.Colors.cardBackground)
            RoundedRectangle(cornerRadius: !viewModel.isScanning ? AppTheme.Radius.lg : AppTheme.Radius.xxl)
                .stroke(AppTheme.Colors.cardStroke, lineWidth: 1.5)
        }
        // 整个背景切换高度时增加动画
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.isScanning)
    }

    private var progressRingSection: some View {
        ZStack {
            // 背景环
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 12)
                .frame(width: 200, height: 200)

            // 进度环
            Circle()
                .trim(from: 0, to: viewModel.scanProgress)
                .stroke(
                    AppTheme.Colors.progressGradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: viewModel.scanProgress)

            // 中心文本
            VStack(spacing: 8) {
                Text("\(Int(viewModel.scanProgress * 100))%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("Analyzing")
                    .font(AppTheme.Fonts.subheadline())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }

    private var statusLabels: some View {
        HStack(spacing: 4) {
            Text("Scanned:")
            Text(viewModel.scannedSize)
        }
        .font(AppTheme.Fonts.caption(.medium))
        .foregroundColor(AppTheme.Colors.textMuted.opacity(0.8))
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
