//
//  AIViewModel.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

struct AIViewInfo: Identifiable {
    let id = UUID()

    let title: LocalizedStringKey
    let image: String
    let prompt: String
}
