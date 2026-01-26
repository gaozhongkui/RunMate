//
//  NavigationManager.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import SwiftUI

@MainActor
@Observable
class NavigationManager {
    static let shared = NavigationManager()

    var path = NavigationPath()
}
