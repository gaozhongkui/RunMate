//
//  MeView.swift
//  RunMate
//

import SwiftUI

struct MeView: View {
    let namespace: Namespace.ID

    @State private var store = AIImageStore.shared
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            AppTheme.Colors.pageGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    profileHeroCard
                    sectionDivider
                    creationsSection
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    // MARK: - 个人信息浮动卡片

    private var profileHeroCard: some View {
        ZStack(alignment: .topTrailing) {

            // 背景紫色光晕装饰
            Circle()
                .fill(Color(hex: "9D50BB").opacity(0.18))
                .frame(width: 220, height: 220)
                .blur(radius: 70)
                .offset(x: -60, y: 30)

            Circle()
                .fill(Color(hex: "00FFFF").opacity(0.08))
                .frame(width: 150, height: 150)
                .blur(radius: 50)
                .offset(x: 80, y: 60)

            // 内容
            VStack(spacing: 0) {

                // 设置按钮行
                HStack {
                    Spacer()
                    Button {
                        // TODO: 设置页
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(Color.white.opacity(0.07)))
                    }
                }
                .padding(.bottom, 8)

                // 头像
                ZStack {
                    // 最外层脉动光晕
                    Circle()
                        .fill(AppTheme.Colors.accentStart.opacity(glowPulse ? 0.25 : 0.08))
                        .frame(width: 108, height: 108)
                        .blur(radius: 12)

                    // 渐变描边环
                    Circle()
                        .stroke(AppTheme.Colors.borderGradient, lineWidth: 2.5)
                        .frame(width: 94, height: 94)

                    // 头像主体
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "2D1F4E"), Color(hex: "1A1B2E")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)

                    Image(systemName: "person.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.bottom, 16)

                // 名称
                Text("Creative Artist")
                    .font(AppTheme.Fonts.headline())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .padding(.bottom, 20)

                // 数据统计栏
                HStack(spacing: 0) {
                    statCell(
                        value: "\(store.records.count)",
                        label: "Works",
                        icon: "photo.stack.fill"
                    )

                    Divider()
                        .frame(width: 1, height: 36)
                        .background(Color.white.opacity(0.12))

                    statCell(
                        value: "AI",
                        label: "Artist",
                        icon: "sparkles"
                    )

                    Divider()
                        .frame(width: 1, height: 36)
                        .background(Color.white.opacity(0.12))

                    statCell(
                        value: "∞",
                        label: "Creative",
                        icon: "bolt.fill"
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1E1535"), Color(hex: "1A1B2E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.55), radius: 28, x: 0, y: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .stroke(AppTheme.Colors.cardStroke, lineWidth: 1.5)
        )
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - 分隔线

    private var sectionDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .semibold))
                Text("AI Creations")
                    .font(AppTheme.Fonts.caption(.semibold))
            }
            .foregroundStyle(AppTheme.Colors.borderGradient)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(hex: "1E1535").opacity(0.9))
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.Colors.borderGradient, lineWidth: 1)
                    )
            )

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
    }

    // MARK: - 创作历史

    private var creationsSection: some View {
        Group {
            if store.records.isEmpty {
                emptyState
            } else {
                VStack(alignment: .trailing, spacing: 10) {
                    Text("\(store.records.count) total")
                        .font(AppTheme.Fonts.caption())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(.horizontal, 20)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2),
                        spacing: 10
                    ) {
                        ForEach(store.records) { record in
                            AIHistoryCard(record: record, store: store)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accentStart.opacity(0.1))
                    .frame(width: 90, height: 90)
                Image(systemName: "photo.stack")
                    .font(.system(size: 34))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            VStack(spacing: 6) {
                Text("No artworks yet")
                    .font(AppTheme.Fonts.subheadline(.semibold))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text("Generate your first AI artwork\nin the AI Lab tab")
                    .font(AppTheme.Fonts.caption())
                    .foregroundColor(AppTheme.Colors.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - 统计格子

    private func statCell(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTheme.Fonts.monospaced(size: 20))
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text(label)
                .font(AppTheme.Fonts.caption2())
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
