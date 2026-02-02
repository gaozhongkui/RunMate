//
//  AILabView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import SwiftUI

struct AILabView: View {
    let namespace: Namespace.ID

    var body: some View {
        WaterfallView(onHeaderTap: {
            NavigationManager.shared.push(.createAI)
        }, onItemTap: { item in
            print("gzk \(item)")
        }).frame(maxWidth: .infinity).frame(maxHeight: .infinity).ignoresSafeArea()
    }
}

#Preview {
    struct PreviewWrapper: View {
        @Namespace var previewNamespace

        var body: some View {
            AILabView(namespace: previewNamespace)
        }
    }

    return PreviewWrapper()
}
