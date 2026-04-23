//
//  SplashView.swift
//  AuraAI
//

import SwiftUI
import FirebaseRemoteConfig

struct SplashView: View {
    @State private var isReady     = false

    // Entry animations
    @State private var logoScale:   CGFloat = 0.4
    @State private var logoOpacity: Double  = 0
    @State private var textOpacity: Double  = 0
    @State private var glowScale:   CGFloat = 0.8

    // Loading dots
    @State private var dotPhase: Int = 0

    var body: some View {
        ZStack {
            if isReady {
                ContentView()
                    .transition(.opacity)
            } else {
                splashBody
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isReady)
        // .task runs once on appear and lives for the full ZStack lifetime — never cancelled mid-flight
        .task { await start() }
    }

    // MARK: - Splash UI

    private var splashBody: some View {
        ZStack {
            // ── Background ──────────────────────────────────────
            Color(hex: "080B16").ignoresSafeArea()

            backgroundOrbs

            // ── Content ─────────────────────────────────────────
            VStack(spacing: 0) {
                Spacer()
                logoSection
                Spacer()
                loadingSection
                    .padding(.bottom, 56)
            }
        }
        .onAppear { runEntryAnimation() }
    }

    // MARK: - Background Orbs

    private var backgroundOrbs: some View {
        ZStack {
            // Purple orb – top left
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "9D50BB").opacity(0.45), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 220
                    )
                )
                .frame(width: 440, height: 440)
                .offset(x: -130, y: -220)
                .blur(radius: 50)
                .scaleEffect(glowScale)

            // Cyan orb – bottom right
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "00FFFF").opacity(0.12), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 160, y: 280)
                .blur(radius: 60)
                .scaleEffect(glowScale)

            // Soft center glow
            Circle()
                .fill(Color(hex: "6E48AA").opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
        }
        .ignoresSafeArea()
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: 28) {

            // Icon
            ZStack {
                // Outer soft ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "9D50BB").opacity(0.25), .clear],
                            center: .center,
                            startRadius: 50,
                            endRadius: 110
                        )
                    )
                    .frame(width: 220, height: 220)

                // Icon backing
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "2D1F4E"), Color(hex: "110D25")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 118, height: 118)
                    .shadow(color: Color(hex: "9D50BB").opacity(0.4), radius: 24, x: 0, y: 0)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "C084FC"),
                                        Color(hex: "00FFFF").opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )

                // Sparkle icon
                Image(systemName: "sparkles")
                    .font(.system(size: 50, weight: .light))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "E040FB"), Color(hex: "9D50BB")],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        Color(hex: "00FFFF").opacity(0.75)
                    )
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)

            // App name + tagline
            VStack(spacing: 10) {
                Text("AuraAI")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "C084FC")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("AI · POWERED · CREATION")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(3.5)
            }
            .opacity(textOpacity)
        }
    }

    // MARK: - Loading Section

    private var loadingSection: some View {
        VStack(spacing: 14) {
            // Animated dots
            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(
                            i == dotPhase
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color(hex: "C084FC"), Color(hex: "9D50BB")],
                                    startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(Color.white.opacity(0.2))
                        )
                        .frame(width: 7, height: 7)
                        .scaleEffect(i == dotPhase ? 1.35 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: dotPhase)
                }
            }

            Text("Preparing your experience…")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.28))
                .tracking(0.5)
        }
        .opacity(textOpacity)
        .task {
            // Cycle dots until ready
            while !isReady {
                try? await Task.sleep(nanoseconds: 380_000_000)
                dotPhase = (dotPhase + 1) % 3
            }
        }
    }

    // MARK: - Animations

    private func runEntryAnimation() {
        // Logo pops in
        withAnimation(.spring(response: 0.75, dampingFraction: 0.68).delay(0.05)) {
            logoScale   = 1.0
            logoOpacity = 1.0
        }
        // Text fades in
        withAnimation(.easeOut(duration: 0.55).delay(0.35)) {
            textOpacity = 1.0
        }
        // Background orbs breathe
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            glowScale = 1.08
        }
    }

    // MARK: - Launch Logic

    @MainActor
    private func start() async {
        // Both child tasks start immediately (async let).
        // Total wait = max(1 s, config fetch time), capped at 3 s.
        async let minDelay: Void   = Task.sleep(nanoseconds: 1_000_000_000) // 1 s floor
        async let configFetch: Void = fetchConfigWithTimeout(seconds: 3)    // 3 s ceiling

        try? await minDelay   // guarantee at least 1 s
        await configFetch     // then wait for fetch if not done yet

        isReady = true
    }

    /// Fetch Remote Config and race it against a timeout.
    /// Returns as soon as the fetch succeeds OR the timeout fires.
    private func fetchConfigWithTimeout(seconds: Double) async {
        await withTaskGroup(of: Void.self) { group in
            // Contestant 1: actual network fetch
            group.addTask {
                _ = try? await RemoteConfig.remoteConfig().fetchAndActivate()
            }
            // Contestant 2: hard timeout
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            }
            // Whichever finishes first wins; cancel the other
            await group.next()
            group.cancelAll()
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView()
}
