//
//  EncryptionManager.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/6.
//

import SwiftUI

import CryptoKit
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

class EncryptionManager {
    static let shared = EncryptionManager()

    // 使用AES-GCM加密图片数据
    func encryptImage(_ imageData: Data, password: String) throws -> Data {
        let key = deriveKey(from: password)
        let sealedBox = try AES.GCM.seal(imageData, using: key)
        return sealedBox.combined!
    }

    // 解密图片数据
    func decryptImage(_ encryptedData: Data, password: String) throws -> Data {
        let key = deriveKey(from: password)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // 从密码派生密钥
    private func deriveKey(from password: String) -> SymmetricKey {
        let passwordData = password.data(using: .utf8)!
        let hashed = SHA256.hash(data: passwordData)
        return SymmetricKey(data: hashed)
    }
}
