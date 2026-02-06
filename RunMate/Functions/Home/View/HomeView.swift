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
                        if viewModel.isScanning {
                            scanningCard
                        }
                        
                        PriSpaceBanner().onTapGesture {
                            NavigationManager.shared.push(.priSpace)
                        }
                        
                        cleaningGrid
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                    .animation(.default, value: viewModel.isScanning)
                }
            }
        }
        .task {
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

    private var scanningCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(colors: [Color.cyan.opacity(0.3), Color.cyan],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing), lineWidth: 8
                    ).frame(width: 120, height: 120)
                   
                Circle()
                    .trim(from: 0, to: viewModel.scanProgress)
                    .stroke(
                        LinearGradient(colors: [Color.cyan, Color.purple],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: viewModel.scanProgress)
            }
               
            Text("AI Scanning...")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
               
            Text("\(viewModel.scannedSize) of \(viewModel.totalSize)").font(.system(size: 14)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(Color(hex: "#1A1A24"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private var cleaningGrid: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 10) {
                ForEach(viewModel.cardLeftItems, id: \.id) { card in
                    HomeItemCard(item: card)
                }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                ForEach(viewModel.cardRightItems, id: \.id) { card in
                    HomeItemCard(item: card)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
