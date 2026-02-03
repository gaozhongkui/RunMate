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
    private let id = Expression<Int64>("id") // 自增主键，用于精确分页

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/pollination_v1.sqlite3")

            // 创建表
            try db?.run(items.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement) // 自增主键
                t.column(imageURL, unique: true) // URL 作为唯一约束，防止重复
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

            // 创建索引加速查询
            _ = try? db?.run(items.createIndex(timestamp, ifNotExists: true))
            _ = try? db?.run(items.createIndex(imageURL, ifNotExists: true))

        } catch {
            print("❌ SQLite 数据库初始化失败: \(error)")
        }
    }

    // MARK: - 保存数据

    /// 批量保存数据
    /// - Parameters:
    ///   - newItems: 需要缓存的数据
    ///   - maxKeepCount: 数据库保留的最大条数（默认保留最近的1000条）
    func saveItems(_ newItems: [PollinationFeedItem], maxKeepCount: Int = 1000) async {
        guard let db = db else { return }
        guard !newItems.isEmpty else { return }

        do {
            // 开启事务，确保批量写入的高性能
            try db.transaction {
                let now = Date()
                for item in newItems {
                    // 使用 INSERT OR IGNORE 避免重复插入
                    try db.run(items.insert(or: .ignore,
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
            
            print("💾 已保存 \(newItems.count) 条数据到数据库")

            // 自动清理超出的旧数据
            await autoCleanup(maxCount: maxKeepCount)

        } catch {
            print("❌ 批量保存失败: \(error)")
        }
    }

    // MARK: - 查询数据

    /// 获取最新的 N 条数据（初始加载）
    /// - Parameter limit: 取出的条数
    func fetchCachedItems(limit: Int = 50) async -> [PollinationFeedItem] {
        var list = [PollinationFeedItem]()
        guard let db = db else { return list }

        do {
            // 按 ID 降序排列（最新的在前面）
            let query = items.order(id.desc).limit(limit)
            for row in try db.prepare(query) {
                let item = rowToItem(row)
                list.append(item)
            }
            print("📖 从数据库加载了 \(list.count) 条数据")
        } catch {
            print("❌ 读取缓存失败: \(error)")
        }
        return list
    }

    /// 获取某个 ID 之前的数据（用于加载更多）
    /// - Parameters:
    ///   - lastId: 当前列表中最后一条数据的 ID
    ///   - limit: 加载的条数
    func fetchItemsBefore(lastId: Int64, limit: Int = 20) async -> [PollinationFeedItem] {
        var list = [PollinationFeedItem]()
        guard let db = db else { return list }

        do {
            // 查询 ID 小于 lastId 的数据（更旧的数据）
            let query = items
                .filter(id < lastId)
                .order(id.desc)
                .limit(limit)
            
            for row in try db.prepare(query) {
                let item = rowToItem(row)
                list.append(item)
            }
            print("📖 加载了 \(list.count) 条历史数据")
        } catch {
            print("❌ 加载历史数据失败: \(error)")
        }
        return list
    }

    /// 根据时间戳加载更旧的数据（备用方案）
    func fetchItemsBefore(timestamp: Date, limit: Int = 20) async -> [PollinationFeedItem] {
        var list = [PollinationFeedItem]()
        guard let db = db else { return list }

        do {
            let query = items
                .filter(self.timestamp < timestamp)
                .order(self.timestamp.desc)
                .limit(limit)
            
            for row in try db.prepare(query) {
                let item = rowToItem(row)
                list.append(item)
            }
            print("📖 加载了 \(list.count) 条历史数据（按时间）")
        } catch {
            print("❌ 加载历史数据失败: \(error)")
        }
        return list
    }

    // MARK: - 辅助方法

    /// 将数据库行转换为 PollinationFeedItem
    private func rowToItem(_ row: Row) -> PollinationFeedItem {
        var item = PollinationFeedItem(
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
        
        // 保存数据库 ID，用于分页
        item.dbId = row[id]
        item.dbTimestamp = row[timestamp]
        
        return item
    }

    /// 获取数据库中的总数据量
    func getTotalCount() async -> Int {
        guard let db = db else { return 0 }
        do {
            return try db.scalar(items.count)
        } catch {
            return 0
        }
    }

    // MARK: - 清理数据

    /// 自动清理超出容量的数据
    private func autoCleanup(maxCount: Int) async {
        guard let db = db else { return }
        do {
            let currentCount = try db.scalar(items.count)
            if currentCount > maxCount {
                let deleteCount = currentCount - maxCount
                
                // 找出最旧的数据（按 ID 升序，取前 deleteCount 个）
                let oldestItems = items.order(id.asc).limit(deleteCount)
                
                // 获取要删除的最大 ID
                if let lastToDelete = try db.pluck(oldestItems.order(id.desc).limit(1)) {
                    let maxIdToDelete = lastToDelete[id]
                    
                    // 删除 ID 小于等于这个值的所有数据
                    let toDelete = items.filter(id <= maxIdToDelete)
                    let deleted = try db.run(toDelete.delete())
                    print("🗑️ 清理了 \(deleted) 条旧数据，保留最新 \(maxCount) 条")
                }
            }
        } catch {
            print("❌ 清理旧缓存失败: \(error)")
        }
    }

    /// 清空所有缓存
    func clearAllCache() async {
        guard let db = db else { return }
        do {
            let deleted = try db.run(items.delete())
            print("🗑️ 已清空所有缓存，共删除 \(deleted) 条数据")
        } catch {
            print("❌ 清空缓存失败: \(error)")
        }
    }

    /// 删除指定 URL 的数据
    func deleteItem(imageURL url: String) async {
        guard let db = db else { return }
        do {
            let item = items.filter(imageURL == url)
            try db.run(item.delete())
            print("🗑️ 已删除图片: \(url)")
        } catch {
            print("❌ 删除失败: \(error)")
        }
    }
}
