//
//  View+Ex.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

extension View {
    func toast(item: Binding<ToastModel?>) -> some View {
        modifier(ToastModifier(toast: item))
    }
}
