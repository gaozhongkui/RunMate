//
//  ToastModel.swift
//  RunMate
//

import SwiftUI

struct ToastModel: Equatable {
    var id = UUID()
    var message: LocalizedStringKey
    var icon: String?
    var duration: Double = 2.0

    static func == (lhs: ToastModel, rhs: ToastModel) -> Bool {
        lhs.id == rhs.id
    }
}
