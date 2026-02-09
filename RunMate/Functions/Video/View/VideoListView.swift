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

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(videos, id: \.id) { video in
                        VideoRowView(video: video)
                            .onTapGesture {
                                selectedVideo = video
                                showPlayer = true
                            }
                    }
                }.padding()
            }
        }
        .navigationTitle("视频列表")
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
}
