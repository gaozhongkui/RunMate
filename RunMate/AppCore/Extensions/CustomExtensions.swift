//
//  CustomExtensions.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import SwiftUI

extension UIDevice {
    /// 判断设备是否为全面屏（或刘海屏）
    var hasNotch: Bool {
        if UIDevice.current.model.contains("iPad") {
            return false
        }
        // 使用 connectedScenes 获取当前活跃的 UIWindowScene
        let scenes = UIApplication.shared.connectedScenes
        guard let windowScene = scenes.first as? UIWindowScene else { return false }

        // 获取主窗口
        guard let window = windowScene.windows.first else { return false }

        // 如果底部安全区域大于 0，则为全面屏设备
        return window.safeAreaInsets.bottom > 0
    }
}
