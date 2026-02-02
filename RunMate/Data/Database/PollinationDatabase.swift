//
//  Untitled.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/2.
//

import Foundation
import SQLite

import Foundation
import SQLite

class PollinationDatabase {
    // 单例模式
    static let shared = PollinationDatabase()

    private var db: Connection?

    // 表定义
    private let items = Table("pollination_cache")

    // 字段定义
    private let imageURL = Expression<String>("imageURL")
    private let prompt = Expression<String?>("prompt")
    private let width = Expression<Int?>("width")
    private let height = Expression<Int?>("height")
    private let seed = Expression<Int?>("seed")
    private let model = Expression<String?>("model")
    private let enhance = Expression<Bool?>("enhance")
    private let safe = Expression<Bool?>("safe")
    private let nologo = Expression<Bool?>("nologo")
    private let quality = Expression<String?>("quality")
    private let status = Expression<String?>("status")
    private let nsfw = Expression<Bool?>("nsfw")
    private let timestamp = Expression<Date>("timestamp") // 用于排序和清理旧数据

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/pollination_v1.sqlite3")

            // 创建表
            try db?.run(items.create(ifNotExists: true) { t in
                t.column(imageURL, primaryKey: true) // 以URL作为唯一标识
                t.column(prompt)
                t.column(width)
                t.column(height)
                t.column(seed)
                t.column(model)
                t.column(enhance)
                t.column(safe)
                t.column(nologo)
                t.column(quality)
                t.column(status)
                t.column(nsfw)
                t.column(timestamp, defaultValue: Date()) // 记录存入时间
            })

            _ = try? db?.run(items.createIndex(timestamp, ifNotExists: true))

        } catch {
            print("SQLite 数据库初始化失败: \(error)")
        }
    }

    /// - Parameters:
    ///   - newItems: 需要缓冲的数据
    ///   - limit: 数据库保留的最大条数（默认保留最近的200条）
    func saveItems(_ newItems: [PollinationFeedItem], maxKeepCount: Int = 200) {
        guard let db = db else { return }

        do {
            // 1. 开启事务，确保批量写入的高性能
            try db.transaction {
                let now = Date()
                for item in newItems {
                    try db.run(items.insert(or: .replace,
                                            imageURL <- item.imageURL,
                                            prompt <- item.prompt,
                                            width <- item.width,
                                            height <- item.height,
                                            seed <- item.seed,
                                            model <- item.model,
                                            enhance <- item.enhance,
                                            safe <- item.safe,
                                            nologo <- item.nologo,
                                            quality <- item.quality,
                                            status <- item.status,
                                            nsfw <- item.nsfw,
                                            timestamp <- now))
                }
            }

            // 2. 自动清理超出的旧数据（保持列表缓冲轻量）
            autoCleanup(maxCount: maxKeepCount)

        } catch {
            print("批量保存失败: \(error)")
        }
    }

    // MARK: - 核心功能：获取列表缓冲

    /// - Parameter limit: 取出的条数
    func fetchCachedItems(limit: Int = 50) -> [PollinationFeedItem] {
        var list = [PollinationFeedItem]()
        guard let db = db else { return list }

        do {
            // 按存入时间倒序排列，确保用户看到的是最新的
            let query = items.order(timestamp.desc).limit(limit)
            for row in try db.prepare(query) {
                let item = PollinationFeedItem(
                    imageURL: row[imageURL],
                    prompt: row[prompt],
                    width: row[width],
                    height: row[height],
                    seed: row[seed],
                    model: row[model],
                    enhance: row[enhance],
                    safe: row[safe],
                    nologo: row[nologo],
                    quality: row[quality],
                    status: row[status],
                    nsfw: row[nsfw]
                )
                list.append(item)
            }
        } catch {
            print("读取缓冲失败: \(error)")
        }
        return list
    }

    // MARK: - 私有工具：清理超出容量的数据

    private func autoCleanup(maxCount: Int) {
        guard let db = db else { return }
        do {
            let currentCount = try db.scalar(items.count)
            if currentCount > maxCount {
                // 找出排在 maxCount 之后的所有旧数据的 URL
                let deleteThreshold = items.order(timestamp.desc).limit(1, offset: maxCount)
                if let thresholdRow = try db.pluck(deleteThreshold) {
                    let thresholdDate = thresholdRow[timestamp]
                    // 删除比这个时间更早的数据
                    let toDelete = items.filter(timestamp < thresholdDate)
                    try db.run(toDelete.delete())
                }
            }
        } catch {
            print("清理旧缓冲失败: \(error)")
        }
    }

    // 清空所有缓存
    func clearAllCache() {
        _ = try? db?.run(items.delete())
    }
}
