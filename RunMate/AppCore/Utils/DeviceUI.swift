//
//  DeviceUI.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import UIKit

enum DeviceUI {
    /// 获取当前窗口的安全区域间距
    static var safeAreaInsets: UIEdgeInsets {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets ?? .zero
    }

    /// 顶部安全区域高度（刘海高度）
    static var topInset: CGFloat {
        safeAreaInsets.top
    }

    /// 底部安全区域高度（底部横条高度）
    static var bottomInset: CGFloat {
        safeAreaInsets.bottom
    }

    /// 判断是否为刘海屏/全面屏
    static var hasNotch: Bool {
        bottomInset > 0
    }
}
