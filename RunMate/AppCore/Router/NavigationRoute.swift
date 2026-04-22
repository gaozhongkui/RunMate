//
//  NavigationRoute.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

enum NavigationRoute: Hashable {
    /// Create AI image
    case createAI(String)
    /// Private image space (encryption)
    case priSpace
    /// Video list
    case videoList([MediaItemViewModel])
    /// Galaxy photo album
    case imageGalaxy
}
