//
//  VideoItemViewModel.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/5.
//
import Foundation
import Photos

@Observable
class MediaItemViewModel: Identifiable, Hashable {
    let id: String
    let phAsset: PHAsset
    var selected: Bool

    let duration: Double
    let width: Int
    let height: Int
    var size: Int64
    let created: Date

    init(phAsset: PHAsset) {
        self.phAsset = phAsset

        self.duration = phAsset.duration
        self.width = phAsset.pixelWidth
        self.height = phAsset.pixelHeight
        self.created = phAsset.creationDate ?? Date()
        self.id = phAsset.localIdentifier
        self.size = 0 // 先给默认值
        self.selected = false
    }

    static func == (lhs: MediaItemViewModel, rhs: MediaItemViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
