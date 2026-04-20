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
    @Environment(\.dismiss) var dismiss

    @State private var toast: ToastModel? = nil
    // 切换页面后重置上一页缩放，避免放大状态残留
    @State private var zoomResetIDs: [PollinationFeedItem.ID: UUID] = [:]

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            // 使用 TabView(.page) 替代 ScrollView，
            // UIPageViewController 能正确识别内嵌 UIScrollView 的边界，
            // 缩放比例为 1 时手势自然传递给翻页控制器，不再卡在一半。
            TabView(selection: $selectedItem) {
                ForEach(items) { item in
                    detailContent(for: item)
                        .tag(item)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    Text(selectedItem.prompt ?? "")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)

                    actionButton()
                        .padding(.bottom, 40)
                }
                .background(
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [Color.black.opacity(0), Color.black.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: geo.size.height * 2)
                        .offset(y: -geo.size.height)
                    }
                )
            }
            .ignoresSafeArea(edges: .bottom)

            closeButton()
        }
        .onChange(of: selectedItem) { old, _ in
            // 离开该页时重置其缩放状态，下次再进入时从 1x 开始
            zoomResetIDs[old.id] = UUID()
        }
        .toast(item: $toast)
    }

    @ViewBuilder
    private func detailContent(for item: PollinationFeedItem) -> some View {
        ZStack(alignment: .center) {
            KFImage.url(URL(string: item.imageURL))
                .placeholder {
                    getPlaceholderView()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .zoomable()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // id 变化时 SwiftUI 重建此视图，Zoomable 状态随之重置
        .id(zoomResetIDs[item.id]?.uuidString ?? item.id)
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
            Button(action: {
                ImageDownloader().downloadAndSaveImage(from: selectedItem.imageURL) { success in
                    toast = success
                        ? ToastModel(message: "Saved to Photos", icon: "checkmark.circle.fill")
                        : ToastModel(message: "Save failed", icon: "xmark.circle.fill")
                }
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

            Button(action: {
                NavigationManager.shared.push(.createAI(selectedItem.prompt ?? ""))
                dismiss()
            }) {
                Text("Create New")
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
