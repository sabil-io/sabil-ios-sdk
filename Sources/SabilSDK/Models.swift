//
//  Models.swift
//  SabilSDK
//
//  Created by Ahmed Saleh on 7/11/22.
//

import Foundation

public struct SabilAppearanceConfig {
    public let locale: String
    public let showBlockingDialog: Bool
    
    public init(locale: String, showBlockingDialog: Bool) {
        self.locale = locale
        self.showBlockingDialog = showBlockingDialog
    }
}

public struct SabilLimitConfig {
    public let mobileLimit: Int
    public let overallLimit: Int
    
    public init(mobileLimit: Int, overallLimit: Int) {
        self.mobileLimit = mobileLimit
        self.overallLimit = overallLimit
    }
}

struct SabilOS: Codable {
    let name: String?
    let version: String?
}

struct SabilDevice: Codable {
    let vendor: String?
    let type: String?
    let model: String?
}

public struct SabilDeviceInfo: Codable {
    let os: SabilOS?
    let device: SabilDevice?
}

public struct SabilDeviceUsage: Codable {
    let deviceID: String
    let deviceInfo: String
    let user: String
    let detachedAt: Date
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case deviceInfo = "device_info"
        case user, createdAt, updatedAt
        case detachedAt = "detacched_at"
    }
}

public struct SabilAttachResponse: Decodable {
    let attachedDevices: Int
    let success: Bool
    
    enum CodingKeys: String, CodingKey {
        case attachedDevices = "attached_devices"
        case success
    }
}
