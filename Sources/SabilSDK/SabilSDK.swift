import Foundation
import UIKit

public struct SabilAppearanceConfig {
    let locale: String
}


public struct SabilLimitConfig {
    let mobileLimit: Int
    let overallLimit: Int
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

public final class Sabil {
    public var clientID: String
    public var secret: String?
    public var userID: String?
    public var appearanceConfig: SabilAppearanceConfig
    public var limitConfig: SabilLimitConfig
    private let baseURL = "http://localhost:8007"
    
    //TODO: Could be a protocol (?)
    /// Called when the number of attached devices for  the user exceed the allotted limit.
    public var onLimitExceeded: (() -> Void)?
    
    /**
     * Called when the user chooses to log out of the current device.
     *
     * This function will be called immeditely after the user detaches the current device from the list of active devices.
     * The user can then continue using the app until the next attach.
     * It is **strongly recommended** that you log the user out when this function fires.
     */
    public var onLogoutCurrentDevice: (() -> Void)?
    
    /**
     * Called when the user chooses to log out a remote device (as apposed to this device).
     *
     * This function will be called immeditely after the user detaches the current device from the list of active devices.
     * The user can then continue using the app until the next attach.
     * It is **strongly recommended** that you log the user out when this function fires.
     */
    public var onLogoutOtherDevice: (() -> Void)?
    
    internal init(clientID: String, secret: String?, appearanceConfig: SabilAppearanceConfig, limitConfig: SabilLimitConfig) {
        self.clientID = clientID
        self.secret = secret
        self.appearanceConfig = appearanceConfig
        self.limitConfig = limitConfig
    }
    
    public func setUserID(_ id: String) {
        self.userID = id
    }
    
    /**
     * Gets a unique ID for the current device.
     *
     * TODO: Add more details on how this works.
     */
    public func getDeviceID() -> String {
        //TODO: persist across re-installs
        let vendorID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        return vendorID
    }
    
    fileprivate func httpRequest(method: String, url urlString: String, body: [String: Any]?) {
        do {
            
            guard let url = URL(string: urlString) else {return}
            var req = URLRequest(url: url)
            req.httpMethod = method
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.addValue("application/json", forHTTPHeaderField: "Accept")
            if let body = body {
                req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            }
            let task = URLSession.shared.dataTask(with: req) { data, response, error in
                if let error = error {
                    print("[Sabil SDK]: \(error)")
                    return
                }
            }
            task.resume()
        } catch {
            print("[Sabil SDK]: \(error)")
            return
        }
    }
    
    /**
     * Adds the device to the user's attached device list.
     *
     * Call this fuction to attach this device to the user. **You must set the userID first.**
     * If the userID is not set, nothing will happen.
     * Once the attaching is successfully concluded, if the user has  exceeded the limit of devices, the "onLimitExceeded" function will be called.
     * - You should call this function immeditely after you know the userID (i.e. after login, or after app launch).
     * - Multiple calls to this function for the same device will not count as different devices for the user.
     * - You should call this function ideally, in every view. But if that's not feasible, we suggest critical views and app launch and when entering foreground.
     */
    public func attach() {
        guard let userID = userID else {
            print("[Sabil SDK]: userID must not be nil.")
            return
        }
        httpRequest(method: "POST",
                    url: "\(baseURL)/attach",
                    body: ["device_id": getDeviceID(), "user": userID])
    }
    
    /**
     * Detaches the devices from the user device list.
     *
     * Call this function only when the device is no longer attached to the user. A common place to call this function is the logout sequence. You should not call this function anywhere else unless you are an advancer user and you know what you're doing.
     */
    public func detach() {
        //TODO: run method in background, handle fails gracefully
    }
    
    /**
     * Returns the devices currently attached to the user.
     */
    public func getUserAttachedDevices() -> [SabilDeviceUsage] {
        //TODO: run method in background, handle fails gracefully
        return []
    }
}
