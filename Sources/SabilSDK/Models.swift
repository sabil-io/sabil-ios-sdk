//
//  Models.swift
//  SabilSDK
//
//  Created by Ahmed Saleh on 7/11/22.
//

import Foundation

public struct SabilAppearanceConfig {
    public let showBlockingDialog: Bool
    
    public init(showBlockingDialog: Bool) {
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

public struct SabilOS: Codable {
    public let name: String?
    public let version: String?
}

public struct SabilDevice: Codable {
    public let vendor: String?
    public let type: String?
    public let model: String?
}

public struct SabilDeviceInfo: Codable {
    public let os: SabilOS?
    public let device: SabilDevice?
}

public struct SabilDeviceUsage: Codable, Identifiable, Hashable {
    public let id: String
    public let deviceID: String
    public let deviceInfo: SabilDeviceInfo
    public let user: String
    public let detachedAt: Date?
    public let createdAt: Date
    public let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case deviceID = "device_id"
        case deviceInfo = "device_info"
        case user, createdAt, updatedAt
        case detachedAt = "detacched_at"
    }

    public static func == (lhs: SabilDeviceUsage, rhs: SabilDeviceUsage) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct SabilAttachResponse: Decodable {
    public let attachedDevices: Int
    public let success: Bool
    
    enum CodingKeys: String, CodingKey {
        case attachedDevices = "attached_devices"
        case success
    }
}

public enum SabilDeviceType: String {
    case mobile
    case tablet
    case computer
}
