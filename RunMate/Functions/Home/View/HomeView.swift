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
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#3A507C"), Color(hex: "#21304A")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                   
                ScrollView {
                    VStack(spacing: 16) {
                        AdvancedScanningCard(viewModel: viewModel)
                        
                        PriSpaceBanner().contentShape(Rectangle()).padding(.horizontal, 16).onTapGesture {
                            NavigationManager.shared.push(.priSpace)
                        }
                        
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
            Text("PhotoVault AI")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            Spacer()
         
            aiButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
       
    private var aiButton: some View {
        HStack(spacing: 0) {
            Image(systemName: "sparkles").font(.system(size: 12, weight: .semibold))
            Text("AI").font(.system(size: 14, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            LinearGradient(colors: [
                Color(hex: "#9D50BB"),
                Color(hex: "#6E48AA")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
        )
        .cornerRadius(20)
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
