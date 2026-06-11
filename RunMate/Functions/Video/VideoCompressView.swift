import SwiftUI

import AVFoundation

// MARK: - 视频压缩视图

struct VideoCompressView: View {
    let video: MediaItemViewModel
    @ObservedObject var compressor: VideoCompressor
    let onComplete: (Bool, String) -> Void
    
    @State private var selectedQuality: CompressionQuality = .medium
    @State private var compressedURL: URL?
    @State private var compressedSize: Int64 = 0
    @State private var showSaveOptions = false
    @State private var isSaving = false
    @State private var showPaywall = false
    @Environment(\.dismiss) private var dismiss
    
    enum CompressionQuality: String, CaseIterable {
        case low = "video_quality_low"
        case medium = "video_quality_medium"
        case high = "video_quality_high"

        var preset: String {
            switch self {
            case .low:
                return AVAssetExportPresetLowQuality
            case .medium:
                return AVAssetExportPresetMediumQuality
            case .high:
                return AVAssetExportPreset1280x720
            }
        }

        var description: String {
            switch self {
            case .low:
                return "video_quality_low_desc"
            case .medium:
                return "video_quality_medium_desc"
            case .high:
                return "video_quality_high_desc"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 原视频信息
                    VStack(alignment: .leading, spacing: 16) {
                        Text("video_compress_original")
                            .font(.headline)
                        
//                        if let thumbnail = video.thumbnail {
//                            Image(uiImage: thumbnail)
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(maxWidth: .infinity)
//                                .frame(height: 200)
//                                .clipShape(RoundedRectangle(cornerRadius: 12))
//                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
//                                InfoRow(icon: "clock", text: video.durationString)
//                                InfoRow(icon: "doc", text: video.fileSizeString)
                            }
                            Spacer()
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    
                    // 压缩质量选择
                    if !compressor.isCompressing && compressedURL == nil {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("video_compress_select_quality")
                                .font(.headline)
                            
                            ForEach(CompressionQuality.allCases, id: \.self) { quality in
                                QualityOptionView(
                                    quality: quality,
                                    isSelected: selectedQuality == quality
                                )
                                .onTapGesture {
                                    selectedQuality = quality
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    
                    // 压缩进度
                    if compressor.isCompressing {
                        VStack(spacing: 16) {
                            ProgressView(value: compressor.compressionProgress) {
                                Text("video_compress_loading")
                                    .font(.headline)
                            }
                            .progressViewStyle(.linear)
                            
                            Text("common_percent_format \(Int(compressor.compressionProgress * 100))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    
                    // 压缩结果
                    if let compressedURL = compressedURL {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                Text("video_compress_complete")
                                    .font(.headline)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("video_compress_original_size")
                                        .foregroundColor(.secondary)
                                    Spacer()
//                                    Text(video.fileSizeString)
//                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("video_compress_compressed_size")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(ByteCountFormatter.string(fromByteCount: compressedSize, countStyle: .file))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("video_compress_space_saved")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(compressionRatio)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                    }
                    
                    // 错误提示
                    if let error = compressor.compressionError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                    
                    // 操作按钮
                    if !compressor.isCompressing {
                        if compressedURL == nil {
                            Button {
                                if StoreManager.shared.isVIP {
                                    startCompression()
                                } else {
                                    showPaywall = true
                                }
                            } label: {
                                Label("video_compress_start", systemImage: "arrow.down.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue)
                                    )
                            }
                        } else {
                            VStack(spacing: 12) {
                                Button {
                                    saveToPhotoLibrary()
                                } label: {
                                    HStack(spacing: 8) {
                                        if isSaving {
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                                .tint(.white)
                                                .scaleEffect(0.85)
                                        } else {
                                            Image(systemName: "square.and.arrow.down")
                                        }
                                        Text(isSaving ? "video_compress_saving" : "video_compress_save_photos")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isSaving ? Color.green.opacity(0.6) : Color.green)
                                    )
                                }
                                .disabled(isSaving)
                                
                                Button {
                                    if let url = compressedURL {
                                        shareVideo(url)
                                    }
                                } label: {
                                    Label("video_compress_share", systemImage: "square.and.arrow.up")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(Color.blue, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("video_compress_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common_close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    private var compressionRatio: String {
//        let saved = video.fileSize - compressedSize
//        let percentage = (Double(saved) / Double(video.fileSize)) * 100
//        return String(format: "%.1f%%", percentage)
        return ""
    }
    
    private func startCompression() {
//        compressor.compressVideo(inputURL: video.url) { result in
//            switch result {
//            case .success(let url):
//                compressedURL = url
//                compressedSize = getFileSize(url: url)
//            case .failure(let error):
//                print("压缩失败: \(error.localizedDescription)")
//            }
//        }
    }
    
    private func getFileSize(url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    private func saveToPhotoLibrary() {
        guard let url = compressedURL, !isSaving else { return }
        isSaving = true
        compressor.saveToPhotoLibrary(url: url) { success, error in
            DispatchQueue.main.async {
                isSaving = false
                if success {
                    onComplete(true, "video_compress_save_success")
                } else {
                    onComplete(false, error?.localizedDescription ?? "video_compress_save_failed")
                }
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
            // 为 iPad 设置 popover
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - 信息行

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - 质量选项视图

struct QualityOptionView: View {
    let quality: VideoCompressView.CompressionQuality
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(quality.rawValue)
                    .font(.headline)
                Text(quality.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}
