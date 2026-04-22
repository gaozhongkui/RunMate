//
//  DeviceUI.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import UIKit

enum DeviceUI {
    /// Get the safe area insets of the current window
    static var safeAreaInsets: UIEdgeInsets {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets ?? .zero
    }

    /// Top safe area height (notch height)
    static var topInset: CGFloat {
        safeAreaInsets.top
    }

    /// Bottom safe area height (home indicator height)
    static var bottomInset: CGFloat {
        safeAreaInsets.bottom
    }

    /// Determine whether the device has a notch or full-screen design
    static var hasNotch: Bool {
        bottomInset > 0
    }
}
