//
//  AILabView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import SwiftUI

struct AILabView: View {
    let namespace: Namespace.ID

    let maxHeight: CGFloat = 80
    let minHeight: CGFloat = 60

    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        let offset = geo.frame(in: .named("scroll")).minY
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: offset
                        )
                    }
                    .frame(height: 0)

                    Color.clear.frame(height: maxHeight)

                    
                    ForEach(0 ..< 50) { i in
                        Text("列表项目 \(i)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                DispatchQueue.main.async {
                    self.scrollOffset = value
                }
            }
            headerView
        }
    }

    var headerView: some View {
        VStack {
            Spacer(minLength: 0)
            HStack {
                Image(systemName: "wand.and.stars")
                Text("Describe the action...").font(.system(size: 15))
                Spacer()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color(.systemBackground)))
            .shadow(radius: 2)
            .padding(.horizontal)
            Spacer(minLength: 0)
        }
        .frame(height: headerHeight)
        .frame(maxWidth: .infinity)
        .background(Color.blue)
        .zIndex(1)
    }

    var headerHeight: CGFloat {
        let height = maxHeight + scrollOffset
        return max(minHeight, height)
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    struct PreviewWrapper: View {
        @Namespace var previewNamespace

        var body: some View {
            // 2. 将声明好的 namespace 传进去
            AILabView(namespace: previewNamespace)
        }
    }

    return PreviewWrapper()
}
