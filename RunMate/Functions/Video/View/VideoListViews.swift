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
        case dateNewest = "Newest"
        case dateOldest = "Oldest"
        case sizeDesc = "Size ↓"
        case sizeAsc = "Size ↑"
        case durationDesc = "Duration ↓"
        case durationAsc = "Duration ↑"
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
            AppTheme.Colors.pageGradient
                .ignoresSafeArea()
                
            ScrollView {
                LazyVStack(spacing: 14) {
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
                // ✅ Fix 2: 底部留出足够空间防止被 TabBar/Home Indicator 遮挡
                .padding(.bottom, 32)
            }
            // ✅ Fix 2: 确保 ScrollView 内容延伸到安全区域外但 padding 留出空间
            .scrollIndicators(.hidden)
        }
        .navigationTitle("My Videos")
        .navigationBarTitleDisplayMode(.large)
        // ✅ Fix 1: 强制导航栏使用深色外观，使标题和返回按钮呈白色
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            // 确保 back button 也是白色
            ToolbarItem(placement: .navigationBarLeading) {
                EmptyView()
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
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
        .alert("Notice", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
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
        HStack(spacing: 0) {
            StatItemView(
                icon: "video.circle.fill",
                title: "Videos",
                value: "\(videos.count)",
                color: Color(hex: "4E9EFF")
            )
            
            Divider()
                .frame(height: 40)
                .background(AppTheme.Colors.cardStroke)

            StatItemView(
                icon: "clock.fill",
                title: "Duration",
                value: formatDuration(totalDuration),
                color: Color(hex: "34D399")
            )
            
            Divider()
                .frame(height: 40)
                .background(AppTheme.Colors.cardStroke)

            StatItemView(
                icon: "square.stack.3d.up.fill",
                title: "Total Size",
                value: formatFileSize(totalSize),
                color: Color(hex: "FB923C")
            )
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                // ✅ Fix 3: 使用更深的卡片背景色，增强对比度
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
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
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color.gradient)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                // ✅ Fix 3: 数值使用纯白色，确保在深色背景下清晰可见
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                // ✅ Fix 3: 次要文字用更高对比度的颜色
                .foregroundColor(Color.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sort Picker View

struct SortPickerView: View {
    @Binding var selection: VideoListView.SortOption
    @Namespace private var sortNamespace
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(VideoListView.SortOption.allCases, id: \.self) { option in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selection = option
                        }
                    } label: {
                        Text(option.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            // ✅ Fix 3: 选中/未选中状态对比更明显
                            .foregroundColor(selection == option ? .white : Color.white.opacity(0.5))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background {
                                if selection == option {
                                    Capsule()
                                        .fill(AppTheme.Colors.accentGradient)
                                        .matchedGeometryEffect(id: "sort", in: sortNamespace)
                                } else {
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Video Row View

struct VideoRowView: View {
    let video: MediaItemViewModel
    
    @State private var thumbnail: UIImage?
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 14) {
            // 缩略图容器
            thumbnailView
            
            // 视频信息
            infoView
            
            // 右侧箭头
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                // ✅ Fix 3: 箭头颜色加深，更易识别
                .foregroundColor(Color.white.opacity(0.4))
                .padding(.trailing, 2)
        }
        .padding(AppTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                // ✅ Fix 3: 卡片背景更深，与页面背景产生明显层次
                .fill(Color.white.opacity(isPressed ? 0.12 : 0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .stroke(Color.white.opacity(isPressed ? 0.25 : 0.14), lineWidth: 1)
                )
                .shadow(
                    color: .black.opacity(isPressed ? 0.3 : 0.2),
                    radius: isPressed ? 6 : 14,
                    y: isPressed ? 2 : 6
                )
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .task {
            await loadThumbnail()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var thumbnailView: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.5)],
                                    startPoint: .center,
                                    endPoint: .bottom
                                )
                            )
                    }
                    // 播放按钮
                    .overlay(alignment: .center) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 38, height: 38)
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .offset(x: 1.5)
                        }
                        .shadow(color: .black.opacity(0.3), radius: 4)
                    }
                    // 时长标签
                    .overlay(alignment: .bottomLeading) {
                        Text(formatDuration(video.duration))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background {
                                Capsule()
                                    .fill(.black.opacity(0.65))
                            }
                            .padding(8)
                    }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 120, height: 90)
                    .overlay {
                        VStack(spacing: 6) {
                            ProgressView()
                                .tint(Color.white.opacity(0.4))
                                .scaleEffect(0.8)
                            Text("Loading")
                                .font(.caption2)
                                .foregroundColor(Color.white.opacity(0.3))
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
        }
    }
    
    @ViewBuilder
    private var infoView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 分辨率 badge
            HStack(spacing: 4) {
                Image(systemName: "aspectratio.fill")
                    .font(.system(size: 9))
                Text("\(video.width) × \(video.height)")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(Color.white.opacity(0.45))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
            )
            
            Spacer()
            
            // 文件大小 — 主信息，最醒目
            Text(formatFileSize(video.size))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                // ✅ Fix 3: 主要数值使用高亮白色
                .foregroundColor(.white)
            
            Spacer()
            
            // 创建日期
            HStack(spacing: 5) {
                Image(systemName: "calendar")
                    .font(.system(size: 10))
                Text(formatDate(video.created))
                    .font(.system(size: 12))
            }
            // ✅ Fix 3: 次要信息有足够对比度但不抢眼
            .foregroundColor(Color.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 90)
    }
    
    // MARK: - Helper Methods
    
    private func loadThumbnail() async {
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: 120 * scale, height: 90 * scale)
        
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
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}


// MARK: - Preview

#Preview {
    @Previewable @Namespace var namespace
    
    NavigationStack {
        VideoListView(
            namespace: namespace,
            videos: []
        )
    }
}
