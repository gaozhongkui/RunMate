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

    @State private var observer = PollinationFeedObserver()

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

                    List(observer.images) { item in
                        VStack(alignment: .leading) {
                            // 异步加载图片
                            AsyncImage(url: URL(string: item.imageURL)) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(height: 200)
                            .cornerRadius(12)

                            Text(item.prompt)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .padding(.top, 4)
                        }
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
        .onAppear {
            observer.startListening()
        }
        .onDisappear {
            observer.stopListening()
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
