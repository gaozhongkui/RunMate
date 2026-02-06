import AVFoundation
import Photos
import SwiftUI

// MARK: - 视频模型

struct VideoItem: Identifiable {
    let id = UUID()
    let url: URL
    let thumbnail: UIImage?
    let duration: TimeInterval
    let fileSize: Int64
    
    var fileSizeString: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var durationString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 视频压缩管理器

@MainActor
@Observable
class VideoCompressor {
    var compressionProgress: Double = 0.0
    var isCompressing: Bool = false
    var compressionError: String?
    
    func compressVideo(inputURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.main.async {
            self.isCompressing = true
            self.compressionProgress = 0.0
            self.compressionError = nil
        }
        
        let asset = AVAsset(url: inputURL)
        
        // 创建输出URL
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        // 删除已存在的文件
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            DispatchQueue.main.async {
                self.isCompressing = false
                self.compressionError = "无法创建导出会话"
            }
            completion(.failure(NSError(domain: "VideoCompressor", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法创建导出会话"])))
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        // 监听进度
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            DispatchQueue.main.async {
                self.compressionProgress = Double(exportSession.progress)
            }
            
            if exportSession.progress >= 1.0 {
                timer.invalidate()
            }
        }
        
        exportSession.exportAsynchronously {
            timer.invalidate()
            
            DispatchQueue.main.async {
                self.isCompressing = false
                self.compressionProgress = 1.0
            }
            
            switch exportSession.status {
            case .completed:
                completion(.success(outputURL))
            case .failed:
                DispatchQueue.main.async {
                    self.compressionError = exportSession.error?.localizedDescription ?? "压缩失败"
                }
                completion(.failure(exportSession.error ?? NSError(domain: "VideoCompressor", code: -2, userInfo: [NSLocalizedDescriptionKey: "压缩失败"])))
            case .cancelled:
                DispatchQueue.main.async {
                    self.compressionError = "压缩已取消"
                }
                completion(.failure(NSError(domain: "VideoCompressor", code: -3, userInfo: [NSLocalizedDescriptionKey: "压缩已取消"])))
            default:
                break
            }
        }
    }
    
    // 保存视频到相册
    func saveToPhotoLibrary(url: URL, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                completion(false, NSError(domain: "VideoCompressor", code: -4, userInfo: [NSLocalizedDescriptionKey: "没有相册访问权限"]))
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                completion(success, error)
            }
        }
    }
}

// MARK: - 视频管理器

@Observable
@MainActor
class VideoManager {
    var videos: [VideoItem] = []
    var isLoading: Bool = false
    
    func loadVideos() {
        isLoading = true
        
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
                return
            }
            
            self?.fetchVideos()
        }
    }
    
    private func fetchVideos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 50
        
        let videos = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        var videoItems: [VideoItem] = []
        
        let group = DispatchGroup()
        
        videos.enumerateObjects { asset, _, _ in
            group.enter()
            
            self.createVideoItem(from: asset) { videoItem in
                if let item = videoItem {
                    videoItems.append(item)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.videos = videoItems
            self?.isLoading = false
        }
    }
    
    private func createVideoItem(from asset: PHAsset, completion: @escaping (VideoItem?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            guard let urlAsset = avAsset as? AVURLAsset else {
                completion(nil)
                return
            }
            
            // 获取缩略图
            self.generateThumbnail(from: urlAsset.url) { thumbnail in
                // 获取文件大小
                let fileSize = self.getFileSize(url: urlAsset.url)
                
                let videoItem = VideoItem(
                    url: urlAsset.url,
                    thumbnail: thumbnail,
                    duration: asset.duration,
                    fileSize: fileSize
                )
                
                completion(videoItem)
            }
        }
    }
    
    func generateThumbnail(from url: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            let time = CMTime(seconds: 1, preferredTimescale: 60)
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    completion(thumbnail)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    private func getFileSize(url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
}
