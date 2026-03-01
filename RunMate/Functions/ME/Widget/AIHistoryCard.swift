//
//  AIHistoryCard.swift
//  RunMate
//

import SwiftUI

struct AIHistoryCard: View {
    let record: AIGeneratedImage
    let store: AIImageStore

    @State private var image: UIImage? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            // 图片 / 占位
            Group {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [Color(hex: "1E1535"), Color(hex: "2A1B50")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.2))
                    )
                }
            }

            // 底部信息渐变遮罩
            VStack(alignment: .leading, spacing: 3) {
                Text(record.styleTitle)
                    .font(AppTheme.Fonts.caption2(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(record.createdAt, format: .dateTime.month(.abbreviated).day().year())
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.78)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        .onAppear {
            image = store.loadImage(for: record)
        }
        .contextMenu {
            Button(role: .destructive) {
                store.delete(record)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
