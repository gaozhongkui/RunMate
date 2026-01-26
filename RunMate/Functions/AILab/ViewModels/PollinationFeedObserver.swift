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
        stopListening() // 启动前先停止旧的，防止内存泄漏
        
        task = Task {
            guard let url = URL(string: "https://image.pollinations.ai/feed") else { return }

            // 1. 配置 Session 禁用所有缓存
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            config.urlCache = nil
            let session = URLSession(configuration: config)

            var request = URLRequest(url: url)
            request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            request.timeoutInterval = 3600 // 给长连接足够的生命周期

            do {
                // 2. 使用 URLSession.bytes 获取流
                let (bytes, response) = try await session.bytes(for: request)
                
                // 检查 HTTP 状态码
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    print("❌ 服务器响应异常")
                    return
                }

                print("✅ SSE 连接已建立")

                for try await line in bytes.lines {
                    // 调试用：打印原始行，看看是不是真的有数据进来
                    // print("Raw line: \(line)")

                    // 3. 必须检查 data: 前缀
                    guard line.hasPrefix("data:") else { continue }
                    
                    let jsonString = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                    guard let data = jsonString.data(using: .utf8) else { continue }

                    do {
                        let item = try JSONDecoder().decode(PollinationFeedItem.self, from: data)
                        
                        // 4. 过滤逻辑：只显示生成完毕的
                        // 注意：如果想实时看过程，可以去掉这个 if
                        if item.status == "end_generating" {
                            self.appendImage(item)
                        }
                    } catch {
                        // 忽略解码失败（有时 SSE 会传一些非 JSON 的心跳包）
                        continue
                    }
                }
            } catch {
                print("⚠️ 连接中断: \(error.localizedDescription)")
                // 这里可以加一个延时自动重连逻辑
            }
        }
    }

    private func appendImage(_ item: PollinationFeedItem) {
//        withAnimation {
//            images.insert(item, at: 0)
//            if images.count > 50 {
//                images.removeLast()
//            }
//        }
    }

    func stopListening() {
        task?.cancel()
        task = nil
    }
}
