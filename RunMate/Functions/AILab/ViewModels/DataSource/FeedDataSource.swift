//
//  FeedDataSource.swift
//  统一的数据源协议和管理器
//
//  Created by Claude on 2026/2/3.
//

import Foundation

// MARK: - 数据源协议

/// 统一的数据源协议
protocol FeedDataSource: AnyObject {
    /// 数据源名称
    var name: String { get }
    
    /// 数据源优先级（数字越小优先级越高）
    var priority: Int { get }
    
    /// 是否可用
    var isAvailable: Bool { get }
    
    /// 开始获取数据
    func startFetching() async throws
    
    /// 停止获取数据
    func stopFetching()
    
    /// 加载更多历史数据
    func loadMore() async throws -> [PollinationFeedItem]
    
    /// 刷新数据
    func refresh() async throws -> [PollinationFeedItem]
    
    /// 数据回调
    var onNewItems: (([PollinationFeedItem]) -> Void)? { get set }
    
    /// 错误回调
    var onError: ((Error) -> Void)? { get set }
}

// MARK: - 数据源错误类型

enum FeedDataSourceError: Error, LocalizedError {
    case networkError(underlying: Error)
    case parseError(underlying: Error)
    case noDataAvailable
    case allSourcesFailed
    case sourceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .parseError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .noDataAvailable:
            return "暂无可用数据"
        case .allSourcesFailed:
            return "所有数据源均不可用"
        case .sourceUnavailable:
            return "数据源不可用"
        }
    }
}

// MARK: - 数据源状态

enum DataSourceStatus {
    case idle           // 空闲
    case fetching       // 正在获取数据
    case available      // 可用
    case unavailable    // 不可用
    case error(Error)   // 错误状态
    
    var isHealthy: Bool {
        switch self {
        case .idle, .fetching, .available:
            return true
        case .unavailable, .error:
            return false
        }
    }
}
