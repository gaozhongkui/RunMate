//
//  FeedDataSource.swift
//  Unified data source protocol and manager
//
//  Created by Claude on 2026/2/3.
//

import Foundation

// MARK: - Data Source Protocol

/// Unified data source protocol
protocol FeedDataSource: AnyObject {
    /// Data source name
    var name: String { get }

    /// Data source priority (smaller number = higher priority)
    var priority: Int { get }

    /// Whether the source is available
    var isAvailable: Bool { get }

    /// Start fetching data
    func startFetching() async throws

    /// Stop fetching data
    func stopFetching()

    /// Load more historical data
    func loadMore() async throws -> [PollinationFeedItem]

    /// Refresh data
    func refresh() async throws -> [PollinationFeedItem]

    /// Data callback
    var onNewItems: (([PollinationFeedItem]) -> Void)? { get set }

    /// Error callback
    var onError: ((Error) -> Void)? { get set }
}

// MARK: - Data Source Error Types

enum FeedDataSourceError: Error, LocalizedError {
    case networkError(underlying: Error)
    case parseError(underlying: Error)
    case noDataAvailable
    case allSourcesFailed
    case sourceUnavailable

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parseError(let error):
            return "Data parse error: \(error.localizedDescription)"
        case .noDataAvailable:
            return "No data available"
        case .allSourcesFailed:
            return "All data sources are unavailable"
        case .sourceUnavailable:
            return "Data source unavailable"
        }
    }
}

// MARK: - Data Source Status

enum DataSourceStatus {
    case idle           // Idle
    case fetching       // Fetching data
    case available      // Available
    case unavailable    // Unavailable
    case error(Error)   // Error state

    var isHealthy: Bool {
        switch self {
        case .idle, .fetching, .available:
            return true
        case .unavailable, .error:
            return false
        }
    }
}
