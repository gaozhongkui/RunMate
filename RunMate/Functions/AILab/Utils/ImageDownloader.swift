//
//  ImageDownloader.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/4.
//

import Photos
import UIKit

class ImageDownloader {
    func downloadAndSaveImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        // 1. 异步下载图片数据
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, let image = UIImage(data: data), error == nil else {
                print("下载失败: \(error?.localizedDescription ?? "未知错误")")
                return
            }
            
            self.saveToPhotoLibrary(image: image)
        }.resume()
    }
    
    private func saveToPhotoLibrary(image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                print("没有相册权限")
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                // 创建一个保存图片的请求
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    print("成功保存到相册！")
                    // 如果需要通知用户，记得回到主线程弹窗
                } else {
                    print("保存失败: \(error?.localizedDescription ?? "")")
                }
            }
        }
    }
}
