//
//  AspectRatioSelector.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI

struct AspectRatioSelector: View {
    let options: [String]

    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                Button(action: {
                    selectedIndex = index
                }) {
                    Text(option)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(
                            selectedIndex == index ? .white : .gray
                        )
                        .frame(maxWidth: .infinity, minHeight: 36)  // 宽度平分，高度固定
                        .background(
                            ZStack {
                                if selectedIndex == index {
                                    LinearGradient(
                                        colors: [Color.purple, Color.blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .cornerRadius(18)
                                } else {
                                    Color.gray.opacity(0.2)
                                        .cornerRadius(18)
                                }
                            }
                        )
                }
            }
        }
    }
}
