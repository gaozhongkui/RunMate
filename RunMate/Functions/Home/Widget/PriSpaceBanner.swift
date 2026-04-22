//
//  PriSpaceBanner.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/5.
//

import SwiftUI

struct PriSpaceBanner: View {
    var body: some View {
        ZStack {
            AppTheme.Colors.bannerGradient
            
            HStack(alignment: .center, spacing: 0) {
                // 2. Left text area
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Absolutely")
                        Text("Private Space")
                    }
                    .font(AppTheme.Fonts.title())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("Bank-grade AES-256 encryption,\nmilitary-level privacy protection.")
                        .font(AppTheme.Fonts.caption())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 12)
                    
                    HStack(spacing: 6) {
                        MiniTag(icon: "lock.fill")
                        MiniTag(icon: "faceid")
                        MiniTag(icon: "eye.slash.fill")
                    }
                }
                .padding(.vertical, 20)
                .padding(.leading, 20)
                
                Spacer()
                
                CompactPhoneMockup()
                    .padding(.trailing, 15)
            }
        }
        .frame(height: 180)
        .cornerRadius(AppTheme.Radius.lg)
        .clipped()
        
    }
    
}

// Compact icon tag
struct MiniTag: View {
    let icon: String
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 10))
            .padding(6)
            .background(Circle().fill(Color.white.opacity(0.1)))
            .foregroundColor(.white.opacity(0.8))
    }
}

// Phone-sized mockup
struct CompactPhoneMockup: View {
    var body: some View {
        ZStack {
            // Phone bezel
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(white: 0.05))
                .frame(width: 80, height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )

            // Breathing glow effect
            Circle()
                .fill(Color.blue.opacity(0.4))
                .frame(width: 50, height: 50)
                .blur(radius: 15)
            
            Text("👆").font(.system(size: 24))
        }
    }
}
