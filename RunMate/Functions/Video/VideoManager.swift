import AVFoundation
import Photos
import SwiftUI

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
