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
    // Singleton
    static let shared = PollinationDatabase()

    private var db: Connection?

    // Table definition
    private let items = Table("pollination_cache")

    // Column definitions
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
    private let timestamp = Expression<Date>("timestamp") // Used for sorting and cleaning old data
    private let id = Expression<Int64>("id") // Auto-increment primary key for precise pagination

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/pollination_v1.sqlite3")

            // Create table
            try db?.run(items.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement) // Auto-increment primary key
                t.column(imageURL, unique: true) // URL as unique constraint to prevent duplicates
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
                t.column(timestamp, defaultValue: Date()) // Record insertion time
            })

            // Create indexes to speed up queries
            _ = try? db?.run(items.createIndex(timestamp, ifNotExists: true))
            _ = try? db?.run(items.createIndex(imageURL, ifNotExists: true))

        } catch {
            print("❌ SQLite database initialization failed: \(error)")
        }
    }

    // MARK: - Save Data

    /// Batch save items
    /// - Parameters:
    ///   - newItems: Items to cache
    ///   - maxKeepCount: Maximum number of records to keep in the database (default: 1000 most recent)
    func saveItems(_ newItems: [PollinationFeedItem], maxKeepCount: Int = 1000) async {
        guard let db = db else { return }
        guard !newItems.isEmpty else { return }

        do {
            // Open transaction to ensure high-performance batch writes
            try db.transaction {
                let now = Date()
                for item in newItems {
                    // Use INSERT OR IGNORE to prevent duplicate inserts
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
            
            print("💾 Saved \(newItems.count) records to database")

            // Automatically clean up records that exceed the limit
            await autoCleanup(maxCount: maxKeepCount)

        } catch {
            print("❌ Batch save failed: \(error)")
        }
    }

    // MARK: - Query Data

    /// Fetch the latest N records (initial load)
    /// - Parameter limit: Number of records to fetch
    func fetchCachedItems(limit: Int = 50) async -> [PollinationFeedItem] {
        var list = [PollinationFeedItem]()
        guard let db = db else { return list }

        do {
            // Sort by ID descending (newest first)
            let query = items.order(id.desc).limit(limit)
            for row in try db.prepare(query) {
                let item = rowToItem(row)
                list.append(item)
            }
            print("📖 Loaded \(list.count) records from database")
        } catch {
            print("❌ Failed to read cache: \(error)")
        }
        return list
    }

    /// Fetch records before a given ID (used for load more)
    /// - Parameters:
    ///   - lastId: The ID of the last item in the current list
    ///   - limit: Number of records to load
    func fetchItemsBefore(lastId: Int64, limit: Int = 20) async -> [PollinationFeedItem] {
        var list = [PollinationFeedItem]()
        guard let db = db else { return list }

        do {
            // Query records with ID less than lastId (older data)
            let query = items
                .filter(id < lastId)
                .order(id.desc)
                .limit(limit)

            for row in try db.prepare(query) {
                let item = rowToItem(row)
                list.append(item)
            }
            print("📖 Loaded \(list.count) historical records")
        } catch {
            print("❌ Failed to load historical data: \(error)")
        }
        return list
    }

    /// Fetch older records by timestamp (fallback approach)
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
            print("📖 Loaded \(list.count) historical records (by timestamp)")
        } catch {
            print("❌ Failed to load historical data: \(error)")
        }
        return list
    }

    // MARK: - Helper Methods

    /// Convert a database row to a PollinationFeedItem
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
        
        // Save database ID for pagination
        item.dbId = row[id]
        item.dbTimestamp = row[timestamp]
        
        return item
    }

    /// Get total record count in the database
    func getTotalCount() async -> Int {
        guard let db = db else { return 0 }
        do {
            return try db.scalar(items.count)
        } catch {
            return 0
        }
    }

    // MARK: - Clean Up Data

    /// Automatically clean up records that exceed the capacity limit
    private func autoCleanup(maxCount: Int) async {
        guard let db = db else { return }
        do {
            let currentCount = try db.scalar(items.count)
            if currentCount > maxCount {
                let deleteCount = currentCount - maxCount
                
                // Find the oldest records (ascending ID order, take first deleteCount)
                let oldestItems = items.order(id.asc).limit(deleteCount)

                // Get the maximum ID to delete
                if let lastToDelete = try db.pluck(oldestItems.order(id.desc).limit(1)) {
                    let maxIdToDelete = lastToDelete[id]

                    // Delete all records with ID less than or equal to this value
                    let toDelete = items.filter(id <= maxIdToDelete)
                    let deleted = try db.run(toDelete.delete())
                    print("🗑️ Cleaned up \(deleted) old records, keeping the latest \(maxCount)")
                }
            }
        } catch {
            print("❌ Failed to clean old cache: \(error)")
        }
    }

    /// Clear all cached data
    func clearAllCache() async {
        guard let db = db else { return }
        do {
            let deleted = try db.run(items.delete())
            print("🗑️ All cache cleared, deleted \(deleted) records")
        } catch {
            print("❌ Failed to clear cache: \(error)")
        }
    }

    /// Delete a record by image URL
    func deleteItem(imageURL url: String) async {
        guard let db = db else { return }
        do {
            let item = items.filter(imageURL == url)
            try db.run(item.delete())
            print("🗑️ Deleted image: \(url)")
        } catch {
            print("❌ Delete failed: \(error)")
        }
    }
}
