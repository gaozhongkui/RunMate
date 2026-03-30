//
//  HomeView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import SwiftUI

import DotLottie

struct HomeView: View {
    let namespace: Namespace.ID
    
    @State private var viewModel = HomeViewModel()
    
    var body: some View {
        ZStack {
            AppTheme.Colors.pageGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                   
                ScrollView {
                    VStack(spacing: 16) {
                        AdvancedScanningCard(viewModel: $viewModel)
                        
                        PriSpaceBanner().contentShape(Rectangle()).padding(.horizontal, 16).onTapGesture {
                            NavigationManager.shared.push(.priSpace)
                        }

                        imageGalaxyBanner
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)

                        cleaningGrid.padding(.horizontal, 16)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 80)
                    .animation(.default, value: viewModel.isScanning)
                }
            }
        }.task {
            await viewModel.loadData()
        }
    }
       
    private var headerView: some View {
        HStack {
            Text("AuraAI")
                .font(AppTheme.Fonts.largeTitle())
                .foregroundColor(AppTheme.Colors.textPrimary)
            Spacer()
         
            aiButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
       
    private var aiButton: some View {
        HStack(spacing: 0) {
            Image(systemName: "sparkles").font(AppTheme.Fonts.caption2(.semibold))
            Text("AI").font(AppTheme.Fonts.subheadline(.bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.accentGradient)
        .cornerRadius(AppTheme.Radius.lg).onTapGesture {
            NavigationManager.shared.selectedTab = .AILab
        }
    }
    
    private var imageGalaxyBanner: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.03, blue: 0.20),
                            Color(red: 0.14, green: 0.06, blue: 0.36)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Nebula glow — right side only, subtle
            Circle()
                .fill(Color(red: 0.45, green: 0.20, blue: 1.0).opacity(0.22))
                .frame(width: 130, height: 130)
                .blur(radius: 38)
                .offset(x: 100, y: 0)

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.50, green: 0.28, blue: 1.0),
                                    Color(red: 0.18, green: 0.45, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Galaxy Album")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)

                    Text("3D Immersive · 5 Cosmic Shapes")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.45))
            }
            .padding(.horizontal, 18)
        }
        .frame(height: 80)
        .contentShape(Rectangle())
        .onTapGesture {
            NavigationManager.shared.push(.imageGalaxy)
        }
    }

    private var cleaningGrid: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 10) {
                ForEach(viewModel.cardLeftItems, id: \.id) { card in
                    HomeItemCard(item: card).contentShape(Rectangle()).onTapGesture {
                        NavigationManager.shared.push(.videoList(card.items ?? []))
                    }
                }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                ForEach(viewModel.cardRightItems, id: \.id) { card in
                    HomeItemCard(item: card).contentShape(Rectangle()).onTapGesture {
                        NavigationManager.shared.push(.videoList(card.items ?? []))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
