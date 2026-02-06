import AVKit
import SwiftUI

// MARK: - 主视图

struct VideoListView: View {
    @State private var videoManager = VideoManager()
    @State private var compressor = VideoCompressor()
    @State private var selectedVideo: VideoItem?
    @State private var showCompressSheet = false
    @State private var showPlayer = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                if videoManager.isLoading {
                    ProgressView("加载视频中...")
                        .scaleEffect(1.5)
                } else if videoManager.videos.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("没有找到视频")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Button("重新加载") {
                            videoManager.loadVideos()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(videoManager.videos) { video in
                                VideoRowView(video: video)
                                    .onTapGesture {
                                        selectedVideo = video
                                        showPlayer = true
                                    }
                                    .contextMenu {
                                        Button {
                                            selectedVideo = video
                                            showCompressSheet = true
                                        } label: {
                                            Label("压缩视频", systemImage: "arrow.down.circle")
                                        }
                                        
                                        Button {
                                            shareVideo(video.url)
                                        } label: {
                                            Label("分享", systemImage: "square.and.arrow.up")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("视频列表")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        videoManager.loadVideos()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                if videoManager.videos.isEmpty {
                    videoManager.loadVideos()
                }
            }
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
    }
    
    private func shareVideo(_ url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController
        {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - 视频行视图

struct VideoRowView: View {
    let video: VideoItem
    
    var body: some View {
        HStack(spacing: 12) {
            // 缩略图
            if let thumbnail = video.thumbnail {
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
                        Image(systemName: "video")
                            .font(.title)
                            .foregroundColor(.gray)
                    )
            }
            
            // 视频信息
            VStack(alignment: .leading, spacing: 6) {
                Text("视频 #\(video.url.lastPathComponent.prefix(8))")
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label(video.durationString, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(video.fileSizeString, systemImage: "doc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            
            Spacer()
            
            // 箭头指示
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
    }
}

// MARK: - 视频播放器视图

struct VideoPlayerView: View {
    let video: VideoItem
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VideoPlayer(player: AVPlayer(url: video.url))
                .ignoresSafeArea()
            
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .background(.black)
    }
}

// MARK: - 预览

struct VideoListView_Previews: PreviewProvider {
    static var previews: some View {
        VideoListView()
    }
}
