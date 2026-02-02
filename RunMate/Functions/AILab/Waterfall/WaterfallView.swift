//
//  WaterfallView.swift
//  UITest
//
//  Created by gaozhongkui on 2025/12/24.
//

import SwiftUI

struct WaterfallView: UIViewControllerRepresentable {
    var onHeaderTap: () -> Void

    var onItemTap: (PollinationFeedItem) -> Void

    func makeUIViewController(context: Context) -> WaterfallViewController {
        let vc = WaterfallViewController()
        vc.onHeaderTap = onHeaderTap
        vc.onItemTap = onItemTap
        return vc
    }

    func updateUIViewController(_ uiViewController: WaterfallViewController, context: Context) {}
}
