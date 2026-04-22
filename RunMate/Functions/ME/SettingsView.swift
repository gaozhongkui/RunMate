//
//  SettingsView.swift
//  RunMate
//

import SwiftUI
import StoreKit
import SafariServices

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var glowPulse = false
    @State private var showFeedbackAlert = false
    @State private var safariURL: URL? = nil

    private var privacyURL: URL { RemoteConfigManager.shared.privacyURL ?? URL(string: "about:blank")! }
    private var termsURL: URL   { RemoteConfigManager.shared.termsURL   ?? URL(string: "about:blank")! }

    var body: some View {
        ZStack {
            AppTheme.Colors.pageGradient
                .ignoresSafeArea()

            // 背景光晕装饰
            Circle()
                .fill(Color(hex: "9D50BB").opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: -100, y: -60)
                .ignoresSafeArea()

            Circle()
                .fill(Color(hex: "00FFFF").opacity(0.06))
                .frame(width: 200, height: 200)
                .blur(radius: 70)
                .offset(x: 140, y: 300)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部导航栏
                navigationBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 用户信息卡片
                        userCard

                        // 设置列表
                        settingsGroup
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
        // Safari 内嵌浏览器（隐私协议 & 服务条款）
        .sheet(item: $safariURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
        // 用户反馈 Alert
        .alert("Send Feedback", isPresented: $showFeedbackAlert) {
            Button("Email Us") {
                openMailFeedback()
            }
            Button("Rate on App Store") {
                requestAppStoreReview()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("How would you like to share your feedback?")
        }
    }

    // MARK: - 导航栏

    private var navigationBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Close")
                        .font(AppTheme.Fonts.caption(.semibold))
                }
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.07))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }

            Spacer()

            Text("Settings")
                .font(AppTheme.Fonts.headline())
                .foregroundColor(AppTheme.Colors.textPrimary)

            Spacer()

            // 占位，保持标题居中
            Color.clear
                .frame(width: 70, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - 用户信息卡片

    private var userCard: some View {
        HStack(spacing: 14) {
            // 头像
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accentStart.opacity(glowPulse ? 0.2 : 0.06))
                    .frame(width: 60, height: 60)
                    .blur(radius: 8)

                Circle()
                    .stroke(AppTheme.Colors.borderGradient, lineWidth: 2)
                    .frame(width: 52, height: 52)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "2D1F4E"), Color(hex: "1A1B2E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("AuraAI")
                    .font(AppTheme.Fonts.subheadline(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                    Text("AI Creator")
                        .font(AppTheme.Fonts.caption2())
                }
                .foregroundStyle(AppTheme.Colors.borderGradient)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1E1535"), Color(hex: "1A1B2E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .stroke(AppTheme.Colors.cardStroke, lineWidth: 1.2)
        )
    }

    // MARK: - 设置分组

    private var settingsGroup: some View {
        VStack(spacing: 2) {
            // 分组标题
            HStack {
                Text("Support & Legal")
                    .font(AppTheme.Fonts.caption(.semibold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .padding(.horizontal, 4)
                Spacer()
            }
            .padding(.bottom, 8)

            // 列表容器
            VStack(spacing: 0) {
                settingsRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    iconColor: Color(hex: "A78BFA"),
                    title: "Feedback",
                    subtitle: "Share your thoughts with us",
                    isFirst: true,
                    isLast: false
                ) {
                    showFeedbackAlert = true
                }

                rowDivider

                settingsRow(
                    icon: "lock.shield.fill",
                    iconColor: Color(hex: "34D399"),
                    title: "Privacy Policy",
                    subtitle: "How we handle your data",
                    isFirst: false,
                    isLast: false
                ) {
                    safariURL = privacyURL
                }

                rowDivider

                settingsRow(
                    icon: "doc.text.fill",
                    iconColor: Color(hex: "60A5FA"),
                    title: "Terms of Service",
                    subtitle: "Usage rules & agreements",
                    isFirst: false,
                    isLast: true
                ) {
                    safariURL = termsURL
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "1E1535"), Color(hex: "1A1B2E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .stroke(AppTheme.Colors.cardStroke, lineWidth: 1.2)
            )
        }
    }

    // MARK: - 单行设置项

    private func settingsRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isFirst: Bool,
        isLast: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // 图标容器
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(iconColor)
                }

                // 文字
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Fonts.subheadline())
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(AppTheme.Fonts.caption2())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                Spacer()

                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 1)
            .padding(.leading, 70)
    }

    // MARK: - Actions

    private func openMailFeedback() {
        let email = RemoteConfigManager.shared.feedbackEmail
        if let url = URL(string: "mailto:\(email)?subject=RunMate%20Feedback") {
            UIApplication.shared.open(url)
        }
    }

    private func requestAppStoreReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - Safari 内嵌浏览器

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = UIColor(Color(hex: "A78BFA"))
        vc.dismissButtonStyle = .close
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - URL + Identifiable（用于 .sheet(item:)）

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
