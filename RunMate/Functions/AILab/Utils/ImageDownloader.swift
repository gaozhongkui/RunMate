//
//  ImageDownloader.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/4.
//

import Photos
import UIKit

class ImageDownloader {
    func downloadAndSaveImage(from urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, let image = UIImage(data: data), error == nil else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            self.saveToPhotoLibrary(image: image, completion: completion)
        }.resume()
    }

    func saveToPhotoLibrary(image: UIImage, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, _ in
                DispatchQueue.main.async { completion(success) }
            }
        }
    }
}
