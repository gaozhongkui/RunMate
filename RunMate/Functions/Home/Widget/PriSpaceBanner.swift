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
            LinearGradient(
                gradient: Gradient(colors: [Color(white: 0.15), Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(alignment: .center, spacing: 0) {
                // 2. 左侧文字区域
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("绝对安全的")
                        Text("私密空间")
                    }
                    .font(.system(size: 24, weight: .bold)) // 减小字体适配手机
                    .foregroundColor(.white)
                    
                    Text("银行级 AES-256 加密，\n军事级隐私防护。")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
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
        .cornerRadius(20)
        .clipped()
        
    }
    
}

// 小巧的图标标签
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

// 适配手机尺寸的 Mockup
struct CompactPhoneMockup: View {
    var body: some View {
        ZStack {
            // 手机外框
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(white: 0.05))
                .frame(width: 80, height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            
            // 呼吸光晕效果
            Circle()
                .fill(Color.blue.opacity(0.4))
                .frame(width: 50, height: 50)
                .blur(radius: 15)
            
            Text("👆")
                .font(.system(size: 24))
        }
    }
}
