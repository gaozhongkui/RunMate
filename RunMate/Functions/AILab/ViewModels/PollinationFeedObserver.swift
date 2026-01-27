//
//  Untitled.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//
import Foundation

import SwiftUI

@MainActor
class PollinationFeedObserver {
    private(set) var images: [PollinationFeedItem] = [] {
        didSet {
            onDataUpdate?(images)
        }
    }

    private var task: Task<Void, Never>?

    var onDataUpdate: (([PollinationFeedItem]) -> Void)?

    func startListening() {
        stopListening()

        // 重置数据
        var tempStorage: [PollinationFeedItem] = []

        task = Task {
            guard let url = URL(string: "https://image.pollinations.ai/feed") else { return }

            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            config.urlCache = nil
            let session = URLSession(configuration: config)

            var request = URLRequest(url: url)
            request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            request.timeoutInterval = 3600

            do {
                let (bytes, response) = try await session.bytes(for: request)

                guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }

                print("✅ 已建立连接，正在积攒数据 ...")

                for try await line in bytes.lines {
                    // 检查取消状态
                    if Task.isCancelled { break }

                    guard line.hasPrefix("data:") else { continue }

                    let jsonString = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                    guard let data = jsonString.data(using: .utf8) else { continue }

                    do {
                        let item = try JSONDecoder().decode(PollinationFeedItem.self, from: data)

                        // 过滤出生成完成的图片
                        if item.status == "end_generating" {
                            // 放入缓冲区
                            tempStorage.append(item)

                            if tempStorage.count % 10 == 0 {
                                await MainActor.run {
                                    withAnimation(.spring()) {
                                        // 一次性批量更新
                                        self.images = tempStorage
                                    }
                                }
                            }

                            if tempStorage.count >= 100 {
                                await MainActor.run {
                                    withAnimation(.spring()) {
                                        // 一次性批量更新
                                        self.images = tempStorage
                                    }
                                }
                                print("🎉 已收集 指定的数量，更新 UI 并停止监听。")
                                self.stopListening() // 停止任务
                                break // 退出循环
                            }
                        }
                    } catch {
                        continue
                    }
                }
            } catch {
                if !Task.isCancelled {
                    print("⚠️ 连接中断: \(error.localizedDescription)")
                }
            }
        }
    }

    func stopListening() {
        task?.cancel()
        task = nil
    }
}
