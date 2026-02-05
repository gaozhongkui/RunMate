//
//  HomeViewModel.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/5.
//

import SwiftUI

@Observable
class HomeViewModel {
    var cardLeftItems: [HomeItem] = []
    var cardRightItems: [HomeItem] = []
    var isScanning = true
    var scanProgress: CGFloat = 0.0
    var scannedSize = "205.71 GB"
    var totalSize = "255.87 GB"

    init() {
        setupMockData()
        startScanAnimation()
    }
    
    private func setupMockData() {
        cardLeftItems = [
            HomeItem(
                title: "Similar Photos",
                size: "2.1GB",
                imageName: "similar_photos",
                viewHeight: 280
            ),
            HomeItem(
                title: "All Videos",
                size: "6.1GB",
                imageName: "all_videos",
                viewHeight: 180
            ),
            HomeItem(
                title: "Screenshots",
                size: "6.1GB",
                imageName: "screenshots",
                viewHeight: 180
            )
        ]
        
        cardRightItems = [
            HomeItem(
                title: "Recordings",
                size: "2.1GB",
                imageName: "",
                viewHeight: 150
            ),
            HomeItem(
                title: "Short Videos",
                size: "2.1GB",
                imageName: "short_videos",
                viewHeight: 350
            )
        ]
    }
        
    private func startScanAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
                
            if self.scanProgress < 1.0 {
                self.scanProgress += 0.02
            } else {
                self.isScanning = false
                timer.invalidate()
            }
        }
    }
        
    func startCleaning() {
        print("开始清理...")
    }
}
