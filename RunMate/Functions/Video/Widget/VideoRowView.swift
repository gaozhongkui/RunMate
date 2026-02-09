//
//  VideoRowView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/9.
//

import AVFoundation
import Photos
import SwiftUI

struct VideoRowView: View {
    let video: MediaItemViewModel
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        HStack(spacing: 12) {
            // 缩略图
            Group {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.black.opacity(0.3))
                                
                                Image(systemName: "play.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 80)
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                }
            }
            
            // 视频信息
            VStack(alignment: .leading, spacing: 6) {
//                Text(video.title)
//                    .font(.headline)
//                    .lineLimit(1)
                
                HStack(spacing: 12) {
//                    if let duration = video.durationString {
//                        Label(duration, systemImage: "clock")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    }
                    
                    Label(video.size.description, systemImage: "doc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .task {
            // 👇 异步加载缩略图
            await loadThumbnail()
        }
    }
    
    // MARK: - 从 PHAsset 加载缩略图
    
    private func loadThumbnail() async {
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: 120 * scale, height: 80 * scale)
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic // 先快速返回低质量，再返回高质量
        options.resizeMode = .fast
        
        let image: UIImage? = await withCheckedContinuation { continuation in
            var isResumed = false
            PHImageManager.default().requestImage(
                for: video.phAsset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { result, info in
                // 👇 只在获取到最终图片时返回
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded, !isResumed {
                    isResumed = true
                    continuation.resume(returning: result)
                }
            }
        }
        
        await MainActor.run {
            self.thumbnail = image
        }
    }
}
