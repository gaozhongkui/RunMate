//
//  Untitled.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//
import Foundation

import SwiftUI

@MainActor
@Observable
class PollinationFeedObserver {
    var images: [PollinationFeedItem] = []
    private var task: Task<Void, Never>?

    func startListening() {
        task = Task {
            guard let url = URL(string: "https://image.pollinations.ai/feed") else { return }

            do {
                // 使用 bytes(from:) 获取异步字节流
                let (bytes, _) = try await URLSession.shared.bytes(from: url)

                for try await line in bytes.lines {
                    // SSE 数据以 "data: " 开头
                    if line.hasPrefix("data: ") {
                        let jsonString = line.replacingOccurrences(of: "data: ", with: "")
                        if let data = jsonString.data(using: .utf8) {
                            // 解析 JSON
                            if let item = try? JSONDecoder().decode(PollinationFeedItem.self, from: data) {
                                // 将新图片插入到列表最前面
                                withAnimation {
                                    self.images.insert(item, at: 0)
                                }
                            }
                        }
                    }
                }
            } catch {
                print("流连接中断: \(error)")
            }
        }
    }

    func stopListening() {
        task?.cancel()
    }
}
