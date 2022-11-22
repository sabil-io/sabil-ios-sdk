//
//  Models.swift
//  SabilSDK
//
//  Created by Ahmed Saleh on 7/11/22.
//

import Foundation

public struct SabilError: Error {
    public let message: String
}

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

public struct SabilDeviceDetails: Codable {
    public let vendor: String?
    public let type: String?
    public let model: String?
}

public struct SabilDeviceInfo: Codable {
    public let os: SabilOS?
    public let device: SabilDeviceDetails?
}

public struct SabilDevice: Codable, Identifiable, Hashable {
    public let id: String
    public let info: SabilDeviceInfo
    public let user: String
    public let createdAt: Date
    public let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case info, user, createdAt, updatedAt
    }

    public static func == (lhs: SabilDevice, rhs: SabilDevice) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public struct SabilAttachResponse: Decodable {
    public let deviceID: String
    public let attachedDevices: Int
    public let success: Bool
    public let blockOverUsage: Bool?
    public let defaultDeviceLimit: Int?

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case attachedDevices = "attached_devices"
        case blockOverUsage = "block_over_usage"
        case defaultDeviceLimit = "default_device_limit"
        case success

    }
}

public struct SabilDeviceIdentity: Decodable {
    public let identity: String
    public let confidence: Double
}

public enum SabilDeviceType: String {
    case mobile
    case tablet
    case computer
}
