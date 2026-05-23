//
//  NavigationManager.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import SwiftUI
import Combine

@MainActor
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var selectedTab: TabStyle = .Create

    @Published var path = NavigationPath()

    func push(_ route: NavigationRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
