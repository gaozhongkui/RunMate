import Photos
import SwiftUI

struct VideoListView: View {
    var namespace: Namespace.ID
    let videos: [MediaItemViewModel]
    
    @State private var compressor = VideoCompressor()
    @State private var selectedVideo: MediaItemViewModel?
    @State private var showCompressSheet = false
    @State private var showPlayer = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var sortOption: SortOption = .dateNewest
    
    enum SortOption: String, CaseIterable {
        case dateNewest = "最新优先"
        case dateOldest = "最旧优先"
        case sizeDesc = "大小(降序)"
        case sizeAsc = "大小(升序)"
        case durationDesc = "时长(降序)"
        case durationAsc = "时长(升序)"
    }
    
    private var sortedVideos: [MediaItemViewModel] {
        switch sortOption {
        case .dateNewest:
            return videos.sorted { $0.created > $1.created }
        case .dateOldest:
            return videos.sorted { $0.created < $1.created }
        case .sizeDesc:
            return videos.sorted { $0.size > $1.size }
        case .sizeAsc:
            return videos.sorted { $0.size < $1.size }
        case .durationDesc:
            return videos.sorted { $0.duration > $1.duration }
        case .durationAsc:
            return videos.sorted { $0.duration < $1.duration }
        }
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
                
            ScrollView {
                LazyVStack(spacing: 16) {
                    // 统计卡片
                    StatsCardView(videos: videos)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                    // 排序选择器
                    SortPickerView(selection: $sortOption)
                        .padding(.horizontal)
                        
                    // 视频列表
                    ForEach(sortedVideos) { video in
                        VideoRowView(video: video)
                            .padding(.horizontal)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedVideo = video
                                    showPlayer = true
                                }
                            }
                         
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("我的视频")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showCompressSheet) {
            if let video = selectedVideo {
                VideoCompressView(
                    video: video,
                    compressor: $compressor,
                    onComplete: { _, message in
                        showCompressSheet = false
                        alertMessage = message
                        showAlert = true
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let video = selectedVideo {
                VideoPlayerView(video: video, isPresented: $showPlayer)
            }
        }
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func shareVideo(_ video: MediaItemViewModel) {
        // 实现分享功能
    }
}

// MARK: - Stats Card View

struct StatsCardView: View {
    let videos: [MediaItemViewModel]
    
    private var totalSize: Int64 {
        videos.reduce(0) { $0 + $1.size }
    }
    
    private var totalDuration: Double {
        videos.reduce(0) { $0 + $1.duration }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            StatItemView(
                icon: "video.circle.fill",
                title: "视频数量",
                value: "\(videos.count)",
                color: .blue
            )
            
            StatItemView(
                icon: "clock.fill",
                title: "总时长",
                value: formatDuration(totalDuration),
                color: .green
            )
            
            StatItemView(
                icon: "square.stack.3d.up.fill",
                title: "总大小",
                value: formatFileSize(totalSize),
                color: .orange
            )
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Stat Item View

struct StatItemView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color.gradient)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sort Picker View

struct SortPickerView: View {
    @Binding var selection: VideoListView.SortOption
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(VideoListView.SortOption.allCases, id: \.self) { option in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selection = option
                        }
                    } label: {
                        Text(option.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selection == option ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background {
                                if selection == option {
                                    Capsule()
                                        .fill(Color.blue.gradient)
                                        .matchedGeometryEffect(id: "sort", in: namespace)
                                } else {
                                    Capsule()
                                        .fill(Color(.systemGray5))
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    @Namespace private var namespace
}

// MARK: - Video Row View (Redesigned)

struct VideoRowView: View {
    let video: MediaItemViewModel
    
    @State private var thumbnail: UIImage?
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 缩略图容器
            ZStack {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            // 渐变遮罩
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .black.opacity(0.4)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .overlay(alignment: .center) {
                            // 播放按钮
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "play.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            // 时长标签
                            Text(formatDuration(video.duration))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    Capsule()
                                        .fill(.black.opacity(0.7))
                                }
                                .padding(8)
                        }
                } else {
                    // 加载占位符
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray5))
                        .frame(width: 140, height: 100)
                        .overlay {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .tint(.gray)
                                Text("加载中...")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                }
            }
            
            // 视频信息
            VStack(alignment: .leading, spacing: 8) {
                // 分辨率
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.fill")
                        .font(.caption2)
                    Text("\(video.width) × \(video.height)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                // 文件大小
                HStack(spacing: 6) {
                    Image(systemName: "doc.fill")
                        .font(.caption)
                        .foregroundStyle(.blue.gradient)
                    
                    Text(formatFileSize(video.size))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                // 创建日期
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(video.created))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 右侧箭头
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(content: {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: .black.opacity(isPressed ? 0.15 : 0.08),
                    radius: isPressed ? 8 : 12,
                    y: isPressed ? 2 : 4
                )
        })
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .task {
            await loadThumbnail()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadThumbnail() async {
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: 140 * scale, height: 100 * scale)
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        
        let image: UIImage? = await withCheckedContinuation { continuation in
            var hasResumed = false
            PHImageManager.default().requestImage(
                for: video.phAsset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { result, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let isError = (info?[PHImageErrorKey] != nil)
                
                if !isDegraded, !isError, !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: result)
                } else if isError, !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: nil)
                }
            }
        }
        
        await MainActor.run {
            self.thumbnail = image
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        formatter.zeroPadsFractionDigits = true
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @Namespace var namespace
    
    VideoListView(
        namespace: namespace,
        videos: [
            // 模拟数据
        ]
    )
}
