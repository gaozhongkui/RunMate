//
//  HomeItemCard.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/5.
//

import SwiftUI

struct HomeItemCard: View {
    let item: HomeItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(.red)
                    .frame(height: item.viewHeight)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                Text(item.size).font(.system(size: 14, weight: .medium)).foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color(hex: "#1A1A24"))
        }
        .cornerRadius(16)
    }
}
