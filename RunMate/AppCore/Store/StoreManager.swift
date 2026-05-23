//
//  StoreManager.swift
//  RunMate
//
//  Created by AI Assistant on 2024/3/21.
//

import StoreKit
import SwiftUI
import Combine

class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()

    // 你的产品 ID (需在 App Store Connect 配置)
    // 建议先在本地 StoreKit Configuration 中匹配这些 ID
    let productIdentifiers = [
        "com.runmate.vip.yearly",
        "com.runmate.vip.lifetime"
    ]

    var isVIP: Bool {
        !purchasedProductIDs.isEmpty
    }

    private var updates: Task<Void, Never>? = nil

    init() {
        updates = observeTransactionUpdates()
        Task {
            await fetchProducts()
            await updateCustomerProductStatus()
        }
    }

    deinit {
        updates?.cancel()
    }

    // 监听实时交易更新（如在其他设备购买或续费）
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                }
            }
        }
    }

    @MainActor
    func fetchProducts() async {
        do {
            self.products = try await Product.products(for: productIdentifiers)
                .sorted(by: { $0.price < $1.price })
        } catch {
            print("Fetch products failed: \(error)")
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedIDs = Set<String>()
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchasedIDs.insert(transaction.productID)
            }
        }
        self.purchasedProductIDs = purchasedIDs
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
