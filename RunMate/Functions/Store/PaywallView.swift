//
//  PaywallView.swift
//  RunMate
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var storeManager = StoreManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedProductID: String?
    @State private var glowPulse = false
    @State private var isPurchasing = false

    let features: [(icon: String, title: String, subtitle: String)] = [
        ("sparkles",            "AI 实验室全模型",   "解锁所有前沿 AI 功能"),
        ("lock.shield.fill",    "隐私空间无限存储",   "军事级加密，保护您的隐私"),
        ("hand.raised.slash.fill", "彻底去除广告",  "纯净体验，零打扰")
    ]

    var body: some View {
        ZStack {
            AppTheme.Colors.pageGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    closeButton
                    heroSection
                    featuresSection
                    plansSection
                    purchaseButton
                    footerLinks
                }
            }
        }
    }

    // MARK: - Subviews

    private var closeButton: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(9)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Crown icon with glow
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accentStart.opacity(0.12))
                    .frame(width: 130, height: 130)
                    .scaleEffect(glowPulse ? 1.18 : 1.0)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: glowPulse)

                Circle()
                    .fill(AppTheme.Colors.accentStart.opacity(0.22))
                    .frame(width: 96, height: 96)

                Image(systemName: "crown.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD760"), Color(hex: "FF9A00")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(hex: "FFD760").opacity(0.55), radius: 14)
            }
            .padding(.top, 12)
            .onAppear { glowPulse = true }

            VStack(spacing: 6) {
                Text("RunMate Pro")
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(AppTheme.Colors.borderGradient)

                Text("解锁完整体验，无任何限制")
                    .font(AppTheme.Fonts.subheadline())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.bottom, 32)
    }

    private var featuresSection: some View {
        VStack(spacing: 10) {
            ForEach(features, id: \.title) { feature in
                FeatureRow(icon: feature.icon, title: feature.title, subtitle: feature.subtitle)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    private var plansSection: some View {
        VStack(spacing: 12) {
            if storeManager.products.isEmpty {
                HStack(spacing: 12) {
                    ProgressView().tint(.white)
                    Text("正在加载方案…")
                        .font(AppTheme.Fonts.caption())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                .frame(height: 96)
            } else {
                ForEach(storeManager.products) { product in
                    ProductCard(
                        product: product,
                        isSelected: selectedProductID == product.id,
                        isRecommended: product.id.contains("yearly")
                    ) {
                        selectedProductID = product.id
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    private var purchaseButton: some View {
        VStack(spacing: 10) {
            Button(action: buySelected) {
                Group {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: 8) {
                            if storeManager.isVIP {
                                Image(systemName: "checkmark.seal.fill")
                            }
                            Text(storeManager.isVIP ? "您已是 Pro 会员" : "立即解锁 Pro")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundColor(canPurchase ? .white : .white.opacity(0.35))
                .background {
                    if canPurchase {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                            .fill(AppTheme.Colors.accentGradient)
                    } else {
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                            .fill(Color.white.opacity(0.12))
                    }
                }
            }
            .disabled(!canPurchase || isPurchasing)
            .shadow(color: canPurchase ? AppTheme.Colors.accentStart.opacity(0.45) : .clear,
                    radius: 14, y: 5)
            .padding(.horizontal, 20)

            if !storeManager.isVIP {
                Text("自动续订 · 可随时取消")
                    .font(AppTheme.Fonts.caption2())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(.bottom, 16)
    }

    private var footerLinks: some View {
        HStack(spacing: 12) {
            Button("恢复购买") {
                Task { await storeManager.updateCustomerProductStatus() }
            }
            Text("·")
            Link("服务协议", destination: URL(string: "https://yourlink.com/terms")!)
            Text("·")
            Link("隐私政策", destination: URL(string: "https://yourlink.com/privacy")!)
        }
        .font(AppTheme.Fonts.caption2())
        .foregroundColor(AppTheme.Colors.textTertiary)
        .padding(.bottom, 36)
    }

    // MARK: - Helpers

    private var canPurchase: Bool {
        selectedProductID != nil && !storeManager.isVIP
    }

    private func buySelected() {
        guard let productID = selectedProductID,
              let product = storeManager.products.first(where: { $0.id == productID }) else { return }
        isPurchasing = true
        Task {
            try? await storeManager.purchase(product)
            await MainActor.run {
                isPurchasing = false
                if storeManager.isVIP { dismiss() }
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.Colors.accentGradient)
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Fonts.subheadline(.semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(AppTheme.Fonts.caption2())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.Colors.accentGradient)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .appCardStyle()
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void

    private var isLifetime: Bool { product.id.contains("lifetime") }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 14) {
                    // Radio
                    ZStack {
                        Circle()
                            .stroke(
                                isSelected ? AppTheme.Colors.accentStart : Color.white.opacity(0.25),
                                lineWidth: 2
                            )
                            .frame(width: 22, height: 22)
                        if isSelected {
                            Circle()
                                .fill(AppTheme.Colors.accentStart)
                                .frame(width: 12, height: 12)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(AppTheme.Fonts.headline())
                            .foregroundColor(.white)

                        if isLifetime {
                            Text("永久有效 · 一次付清")
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        } else {
                            let monthly = product.price / 12
                            Text("约 \(monthly.formatted(product.priceFormatStyle))/月")
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(product.displayPrice)
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Text(isLifetime ? "永久" : "每年")
                            .font(AppTheme.Fonts.caption2())
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .fill(isSelected
                              ? AppTheme.Colors.accentStart.opacity(0.18)
                              : AppTheme.Colors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .stroke(
                            isSelected
                            ? LinearGradient(
                                colors: [AppTheme.Colors.accentStart, AppTheme.Colors.accentEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ),
                            lineWidth: isSelected ? 2 : 1
                        )
                )

                // Badge
                if isRecommended {
                    Text("推荐")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppTheme.Colors.accentGradient))
                        .offset(x: -14, y: -9)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
