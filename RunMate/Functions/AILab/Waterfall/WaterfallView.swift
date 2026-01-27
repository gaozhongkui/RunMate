//
//  WaterfallView.swift
//  UITest
//
//  Created by gaozhongkui on 2025/12/24.
//

import SwiftUI

struct WaterfallView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> WaterfallViewController {
        let vc = WaterfallViewController()
        return vc
    }

    func updateUIViewController(_ uiViewController: WaterfallViewController, context: Context) {}
}
