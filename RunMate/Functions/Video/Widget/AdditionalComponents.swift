import SwiftUI
import Photos

// MARK: - Grid Layout Option

struct VideoGridView: View {
    let videos: [MediaItemViewModel]
    let columns: Int
    @Binding var selectedVideo: MediaItemViewModel?
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(videos) { video in
                VideoGridItemView(video: video)
                    .aspectRatio(16/9, contentMode: .fit)
                    .onTapGesture {
                        selectedVideo = video
                    }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Grid Item View

struct VideoGridItemView: View {
    let video: MediaItemViewModel
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay {
                        ProgressView()
                    }
            }
            
            // 渐变遮罩
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            
            // 信息层
            VStack {
                Spacer()
                
                HStack {
                    // 时长
                    Label(video.durationString, systemImage: "clock.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background {
                            Capsule()
                                .fill(.black.opacity(0.5))
                        }
                    
                    Spacer()
                    
                    // 分辨率标签
                    Text(video.resolution.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background {
                            Capsule()
                                .fill(video.resolution.color.opacity(0.8))
                        }
                }
                .padding(8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        .task {
            thumbnail = await video.loadThumbnail()
        }
    }
}

// MARK: - Empty State View

struct VideoEmptyStateView: View {
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        message: String = "暂无视频",
        systemImage: String = "video.slash",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background {
                            Capsule()
                                .fill(Color.blue.gradient)
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String
    
    init(message: String = "加载中...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter Bar View

struct FilterBarView: View {
    @Binding var selectedResolution: VideoResolution?
    @Binding var minDuration: Double
    @Binding var maxDuration: Double
    
    var body: some View {
        VStack(spacing: 12) {
            // 分辨率筛选
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "全部",
                        isSelected: selectedResolution == nil,
                        action: { selectedResolution = nil }
                    )
                    
                    ForEach(VideoResolution.allCases, id: \.self) { resolution in
                        FilterChip(
                            title: resolution.rawValue,
                            icon: resolution.icon,
                            color: resolution.color,
                            isSelected: selectedResolution == resolution,
                            action: { selectedResolution = resolution }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // 时长筛选
            HStack {
                Text("时长范围:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(minDuration))s - \(Int(maxDuration))s")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
        .padding(.horizontal)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    var color: Color = .blue
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(isSelected ? color.gradient : Color(.systemGray5).gradient)
            }
        }
    }
}

// MARK: - Selection Toolbar

struct SelectionToolbarView: View {
    let selectedCount: Int
    let totalCount: Int
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void
    let onDelete: () -> Void
    let onCompress: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 选择状态
            Text("\(selectedCount)/\(totalCount) 已选择")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            // 操作按钮
            HStack(spacing: 12) {
                ToolbarButton(
                    icon: selectedCount == totalCount ? "checkmark.circle.fill" : "circle",
                    action: selectedCount == totalCount ? onDeselectAll : onSelectAll
                )
                
                ToolbarButton(
                    icon: "arrow.down.circle",
                    color: .blue,
                    action: onCompress,
                    disabled: selectedCount == 0
                )
                
                ToolbarButton(
                    icon: "square.and.arrow.up",
                    color: .green,
                    action: onShare,
                    disabled: selectedCount == 0
                )
                
                ToolbarButton(
                    icon: "trash",
                    color: .red,
                    action: onDelete,
                    disabled: selectedCount == 0
                )
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        }
    }
}

// MARK: - Toolbar Button

struct ToolbarButton: View {
    let icon: String
    var color: Color = .primary
    let action: () -> Void
    var disabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(disabled ? .gray : color)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(Color(.systemGray6))
                }
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
    }
}

// MARK: - Search Bar

struct VideoSearchBar: View {
    @Binding var searchText: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索视频...", text: $searchText)
                .focused($isFocused)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        }
        .padding(.horizontal)
    }
}

// MARK: - View Mode Picker

struct ViewModePicker: View {
    @Binding var mode: ViewMode
    
    enum ViewMode: String, CaseIterable {
        case list = "列表"
        case grid = "网格"
        
        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .grid: return "square.grid.2x2"
            }
        }
    }
    
    var body: some View {
        Picker("视图模式", selection: $mode) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Label(mode.rawValue, systemImage: mode.icon)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview("Grid View") {
    @Previewable @State var selectedVideo: MediaItemViewModel? = nil
    
    VideoGridView(
        videos: [],
        columns: 2,
        selectedVideo: $selectedVideo
    )
}

#Preview("Empty State") {
    VideoEmptyStateView(
        message: "暂无视频",
        systemImage: "video.slash",
        actionTitle: "导入视频",
        action: {}
    )
}

#Preview("Filter Bar") {
    @Previewable @State var resolution: VideoResolution? = nil
    @Previewable @State var minDuration: Double = 0
    @Previewable @State var maxDuration: Double = 300
    
    FilterBarView(
        selectedResolution: $resolution,
        minDuration: $minDuration,
        maxDuration: $maxDuration
    )
}
