//
//  SplashView.swift
//  RunMate
//
//  Created by Cursor on 2026/4/22.
//

import SwiftUI
import FirebaseRemoteConfig

struct SplashView: View {
    @State private var isReady = false
    @State private var didStart = false

    var body: some View {
        Group {
            if isReady {
                ContentView()
            } else {
                splashBody
            }
        }
        .task {
            guard !didStart else { return }
            didStart = true
            await start()
        }
    }

    private var splashBody: some View {
        ZStack {
            AppTheme.Colors.pageGradient
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 76, weight: .regular))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.white, AppTheme.Colors.accentStart)

                Text("AuraAI")
                    .font(AppTheme.Fonts.largeTitle())
                    .foregroundStyle(.white)

                Text("Loading…")
                    .font(AppTheme.Fonts.subheadline())
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                ProgressView()
                    .tint(.white.opacity(0.9))
                    .padding(.top, 6)
            }
            .padding(.horizontal, 24)
        }
    }

    @MainActor
    private func start() async {
        async let minDelay: Void = minimumDelay() // keep splash visible briefly

        let status = await withCheckedContinuation { (continuation: CheckedContinuation<RemoteConfigFetchAndActivateStatus, Never>) in
            RemoteConfigManager.shared.fetchAndActivate { status, _ in
                continuation.resume(returning: status)
            }
        }

        _ = status
        _ = await minDelay
        withAnimation(.easeOut(duration: 0.25)) {
            isReady = true
        }
    }

    private func minimumDelay() async {
        try? await Task.sleep(nanoseconds: 650_000_000)
    }
}

#Preview {
    SplashView()
}

