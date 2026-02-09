//
//  NavigationRoute.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

enum NavigationRoute: Hashable {
    /// 创建图片AI
    case createAI
    /// 图片加密
    case priSpace
    /// 视频列表
    case videoList([MediaItemViewModel])
}
