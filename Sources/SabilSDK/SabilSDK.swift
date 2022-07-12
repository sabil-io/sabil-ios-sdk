import Foundation
import UIKit
import SwiftUI

@available(iOS 13.0.0, *)
public final class Sabil {
    public static let shared = Sabil()

    public var clientID: String?
    public var secret: String?
    public var userID: String?
    public var appearanceConfig = SabilAppearanceConfig(locale: "en", showBlockingDialog: true)
    public var limitConfig = SabilLimitConfig(mobileLimit: 1, overallLimit: 2)
    private let baseURL = "http://localhost:8007"
    private let window = UIWindow(frame: UIScreen.main.bounds)
    private let rootVC = UIViewController()

    //TODO: Could be a protocol (?)
    /// Called when the number of attached devices for  the user exceed the allotted limit.
    public var onLimitExceeded: ((Int) -> Void)?

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

    public func config(clientID: String, secret: String? = nil, appearanceConfig: SabilAppearanceConfig? = nil, limitConfig: SabilLimitConfig? = nil) {
        self.clientID = clientID
        self.secret = secret
        if let appearanceConfig = appearanceConfig {
            self.appearanceConfig = appearanceConfig
        }
        if let limitConfig = limitConfig {
            self.limitConfig = limitConfig
        }
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

    fileprivate func httpRequest(method: String, url urlString: String, body: [String: Any]?, onCompletion: ((Data?) -> Void)? = nil) {
        do {
            guard let clientID = clientID else {
                print("[Sabil SDK]: clientID must not be nil.")
                return
            }
            guard let url = URL(string: urlString) else {return}
            var req = URLRequest(url: url)
            req.httpMethod = method
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.addValue("application/json", forHTTPHeaderField: "Accept")
            req.addValue("Basic \(clientID):\(secret ?? "")", forHTTPHeaderField: "Authorization")
            if let body = body {
                req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            }
            let task = URLSession.shared.dataTask(with: req) { data, response, error in
                if let error = error {
                    print("[Sabil SDK]: \(error)")
                    return
                }
                onCompletion?(data)
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
     * Call this fuction to attach this device to the user. **You must set the userID & clientID first.**
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
        let deviceInfo = getDeviceInfo()
        let body: [String : Any] = ["device_id": getDeviceID(), "user": userID, "device_info": deviceInfo]
        httpRequest(method: "POST", url: "\(baseURL)/usage/attach", body: body) { data in

            guard let data = data else { return }
            let decoder = JSONDecoder()
            guard let attachResponse = try? decoder.decode(SabilAttachResponse.self, from: data) else { return }
            // TODO: handle mobile specific limits
            guard attachResponse.attachedDevices > self.limitConfig.overallLimit else {
                return
            }
            DispatchQueue.main.async {
                self.onLimitExceeded?(attachResponse.attachedDevices)
            }
            guard self.appearanceConfig.showBlockingDialog else {
                return
            }


            self.rootVC.view.backgroundColor = .clear
            self.window.rootViewController = rootVC
            DispatchQueue.main.async {
                self.window.makeKeyAndVisible()
                let dialogViewContoller = UIHostingController(rootView: DialogView())
                self.rootVC.present(dialogViewContoller, animated: true)

            }
        }
    }

    fileprivate func getDeviceInfo() -> [String: Any] {
        var type = "mobile"
        if UIDevice.current.model.contains("iPad") {
            type = "tablet"
        }
        return [
            "os": ["name": UIDevice.current.systemName, "version": UIDevice.current.systemVersion],
            "device": [
                "vendor": "Apple",
                "model": UIDevice.current.model,
                "type": type]]
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


