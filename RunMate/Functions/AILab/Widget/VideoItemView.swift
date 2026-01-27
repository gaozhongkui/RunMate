//
//  VideoItemView.swift
//  DeepClean
//
//  Created by gaozhongkui on 2026/1/5.
//  Copyright © 2026 CleanNow. All rights reserved.
//

import Kingfisher
import SwiftUI

struct VideoItemView: View {
    let item: PollinationFeedItem
    var onClickTap: (() -> Void)? = nil

    // 定义显示尺寸，用于降采样
    private let targetSize = CGSize(width: 170, height: 234)

    var body: some View {
        ZStack(alignment: .bottom) {
            if let url = URL(string: item.imageURL) {
                KFImage(url)
                    .placeholder {
                        Color(hex: "#1A1629").overlay(ProgressView().tint(.white))
                    }
                    .setProcessor(DownsamplingImageProcessor(size: targetSize))
                    .scaleFactor(UIScreen.main.scale)
                    .cacheMemoryOnly(false)
                    .fade(duration: 0.25)
                    .resizable()
                    .scaledToFill()
                    .frame(width: targetSize.width, height: targetSize.height)
                    .clipped()
            } else {
                Color.gray.frame(width: targetSize.width, height: targetSize.height)
            }

            // 文本部分保持不变
            Text(item.prompt ?? "No Prompt")
                .font(.system(size: 14))
                .lineLimit(2)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .foregroundColor(.white)
                .frame(width: targetSize.width)
                .background(Color.black.opacity(0.6))
        }
        .background(Color(hex: "#C9DFD9"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .contentShape(Rectangle())
        .onTapGesture {
            onClickTap?()
        }
    }
}
