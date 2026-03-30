//
//  NavigationDestinationAI.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

struct NavigationDestinationImage: ViewModifier {
    var namespace: Namespace.ID

    @State var router: NavigationManager = .shared

    func body(content: Content) -> some View {
        content.navigationDestination(for: NavigationRoute.self) { node in
            switch node {
            case .createAI(let prompt):
                CreateAIView(namespace: namespace,defaultAIPrompt: prompt)
            case .priSpace:
                ImageEncryptionView(namespace: namespace)
            case .videoList(let videoItems):
                VideoListView(namespace: namespace,videos: videoItems)
            case .imageGalaxy:
                ImageGalaxyCanvas(namespace: namespace)
            }
        }
    }
}
