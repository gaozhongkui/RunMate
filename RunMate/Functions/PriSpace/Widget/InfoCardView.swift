//
//  InfoCardView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/6.
//

import SwiftUI

struct InfoCardView: View {
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "lock.shield.fill")
                .font(.title)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 5) {
                Text("安全加密存储")
                    .font(.headline)
                Text("使用AES-256加密保护您的图片")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
