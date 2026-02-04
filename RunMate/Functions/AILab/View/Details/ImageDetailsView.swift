//
//  ImageDetailsView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/3.
//

import Kingfisher
import SwiftUI
import Zoomable

struct ImageDetailsView: View {
    @Binding var items: [PollinationFeedItem]
    @State var selectedItem: PollinationFeedItem
    @State private var scrollID: PollinationFeedItem.ID?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(items) { item in
                        detailContent(for: item).containerRelativeFrame(.horizontal).id(item.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollID)
            .scrollTargetBehavior(.paging)
            .ignoresSafeArea()

            VStack {
                closeButton()
                Spacer()
                actionButton()
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            scrollID = selectedItem.id
        }
        .onChange(of: scrollID) { _, newID in
            if let newID = newID, let item = items.first(where: { $0.id == newID }) {
                selectedItem = item
            }
        }
    }

    @ViewBuilder
    private func detailContent(for item: PollinationFeedItem) -> some View {
        ZStack(alignment: .center) {
            KFImage.url(URL(string: item.imageURL))
                .placeholder {
                    getPlaceholderView()
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .zoomable()

            VStack {
                Spacer()
                Text(item.prompt ?? "").font(.system(size: 16)).foregroundColor(.white).lineLimit(2).frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16).padding(.bottom, 120 + (UIDevice.current.hasNotch ? 0 : 34))
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func getPlaceholderView() -> some View {
        ZStack {
            Image("img_loading").resizable()
            ProgressView().tint(.white)
        }
    }

    private func closeButton() -> some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
        }
    }

    private func actionButton() -> some View {
        HStack(spacing: 12) {
            // 下载按钮
            Button(action: {
                print("下载: \(selectedItem.imageURL)")
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    Image(systemName: "arrow.down.to.line")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            // 生成相似按钮
            Button(action: { print("生成相似: \(selectedItem)") }) {
                Text("Generate Similar")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [Color(hex: "#C260F5"), Color(hex: "#6034E4")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .cornerRadius(22)
                    )
            }
        }
        .padding(.horizontal, 30)
    }
}
