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

    private var privacyURL: URL { RemoteConfigManager.shared.privacyURL ?? URL(string: "about:blank")! }
    private var termsURL: URL   { RemoteConfigManager.shared.termsURL   ?? URL(string: "about:blank")! }

    
    let features: [(icon: String, title: String, subtitle: String)] = [
        ("sparkles",            "AI Lab All Models",   "Unlock all advanced AI features"),
        ("lock.shield.fill",    "Unlimited Vault",   "Military-grade encryption for privacy"),
        ("hand.raised.slash.fill", "Remove All Ads",  "Pure experience, zero distractions")
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
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accentStart.opacity(0.12))
                    .frame(width: 88, height: 88)
                    .scaleEffect(glowPulse ? 1.18 : 1.0)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: glowPulse)

                Circle()
                    .fill(AppTheme.Colors.accentStart.opacity(0.22))
                    .frame(width: 64, height: 64)

                Image(systemName: "crown.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD760"), Color(hex: "FF9A00")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(hex: "FFD760").opacity(0.5), radius: 10)
            }
            .padding(.top, 6)
            .onAppear { glowPulse = true }

            VStack(spacing: 4) {
                Text("PriSpace AI Pro")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(AppTheme.Colors.borderGradient)

                Text("Unlock full experience without limits")
                    .font(AppTheme.Fonts.caption())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.bottom, 18)
    }

    private var featuresSection: some View {
        VStack(spacing: 8) {
            ForEach(features, id: \.title) { feature in
                FeatureRow(icon: feature.icon, title: feature.title, subtitle: feature.subtitle)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var plansSection: some View {
        VStack(spacing: 12) {
            if storeManager.products.isEmpty {
                HStack(spacing: 12) {
                    ProgressView().tint(.white)
                    Text("Loading plans...")
                        .font(AppTheme.Fonts.caption())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
                .frame(height: 96)
            } else {
                ForEach(storeManager.products) { product in
                    ProductCard(
                        product: product,
                        isSelected: selectedProductID == product.id,
                        isRecommended: product.id.contains("lifetime")
                    ) {
                        selectedProductID = product.id
                    }
                }
            }
        }
        .onChange(of: storeManager.products) { products in
            if selectedProductID == nil, let lifetime = products.first(where: { $0.id.contains("lifetime") }) {
                selectedProductID = lifetime.id
            }
        }
        .onAppear {
            if selectedProductID == nil, let lifetime = storeManager.products.first(where: { $0.id.contains("lifetime") }) {
                selectedProductID = lifetime.id
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private var purchaseButton: some View {
        VStack(spacing: 8) {
            Button(action: buySelected) {
                Group {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: 8) {
                            if storeManager.isVIP {
                                Image(systemName: "checkmark.seal.fill")
                            }
                            Text(storeManager.isVIP ? "You are a Pro Member" : "Unlock Pro Now")
                                .font(.system(size: 17, weight: .bold))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
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
                Text("Auto-renewable · Cancel anytime")
                    .font(AppTheme.Fonts.caption2())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(.bottom, 12)
    }

    private var footerLinks: some View {
        HStack(spacing: 12) {
            Button("Restore Purchase") {
                Task { await storeManager.updateCustomerProductStatus() }
            }
            Text("·")
            Link("Terms", destination: termsURL)
            Text("·")
            Link("Privacy", destination: privacyURL)
        }
        .font(AppTheme.Fonts.caption2())
        .foregroundColor(AppTheme.Colors.textTertiary)
        .padding(.bottom, 24)
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
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.Colors.accentGradient)
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppTheme.Fonts.caption(.semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(AppTheme.Fonts.caption2())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.accentGradient)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
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
                                lineWidth: 1.5
                            )
                            .frame(width: 18, height: 18)
                        if isSelected {
                            Circle()
                                .fill(AppTheme.Colors.accentStart)
                                .frame(width: 10, height: 10)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(AppTheme.Fonts.headline())
                            .foregroundColor(.white)

                        if isLifetime {
                            Text("Lifetime · One-time payment")
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        } else {
                            let monthly = product.price / 12
                            Text("Approx. \(monthly.formatted(product.priceFormatStyle))/mo")
                                .font(AppTheme.Fonts.caption())
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(product.displayPrice)
                            .font(.system(size: 17, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Text(isLifetime ? "LIFETIME" : "YEARLY")
                            .font(AppTheme.Fonts.caption2())
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
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
                    Text("BEST VALUE")
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
