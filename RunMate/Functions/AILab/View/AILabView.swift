//
//  AILabView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import SwiftUI

struct AILabView: View {
    let namespace: Namespace.ID
    @State private var currentItem: PollinationFeedItem? = nil

    var body: some View {
        WaterfallView(onHeaderTap: {
            NavigationManager.shared.push(.createAI)
        }, onItemTap: { item in
            currentItem = item
            print("gzk \(item)")
        }).frame(maxWidth: .infinity, maxHeight: .infinity).ignoresSafeArea()
            .sheet(item: $currentItem) { item in
                ImageDetailsView(item: item)
            }
    }
}
