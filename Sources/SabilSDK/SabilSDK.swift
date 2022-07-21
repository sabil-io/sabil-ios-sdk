import Foundation
import UIKit
import SwiftUI

public final class Sabil {
    public static let shared = Sabil()

    public var clientID: String?
    public var secret: String?
    public var userID: String?
    public var appearanceConfig = SabilAppearanceConfig(showBlockingDialog: true)
    private let baseURL = "https://api.sabil.io"
    private var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    private let rootVC = UIViewController()
    private let viewModel = DialogViewModel(currentDeviceID: "",
                                            attachedDevices: [],
                                            limitConfig: SabilLimitConfig(mobileLimit: 1, overallLimit: 2))

    /// Called when the number of attached devices for  the user exceed the allotted limit.
    public var onLimitExceeded: ((Int) -> Void)?

    /**
     * Called when the user chooses to log out of the current device.
     *
     * This function will be called immeditely after the user detaches the current device from the list of active devices.
     * The user can then continue using the app until the next attach.
     * It is **strongly recommended** that you log the user out when this function fires.
     */
    public var onLogoutCurrentDevice: ((SabilDeviceUsage) -> Void)?

    /**
     * Called when the user chooses to log out a remote device (as apposed to this device).
     *
     * This function will be called immeditely after the user detaches the current device from the list of active devices.
     * The user can then continue using the app until the next attach.
     * It is **strongly recommended** that you log the user out when this function fires.
     */
    public var onLogoutOtherDevice: ((SabilDeviceUsage) -> Void)?

    public func config(clientID: String, secret: String? = nil, appearanceConfig: SabilAppearanceConfig? = nil, limitConfig: SabilLimitConfig? = nil) {
        viewModel.currentDeviceID = getDeviceID()
        self.clientID = clientID
        self.secret = secret
        if let appearanceConfig = appearanceConfig {
            self.appearanceConfig = appearanceConfig
        }
        if let limitConfig = limitConfig {
            self.viewModel.limitConfig = limitConfig
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

    fileprivate func httpRequest(method: String, url urlString: String, body: [String: Any]? = nil, onCompletion: ((Data?) -> Void)? = nil) {
        do {
            guard let clientID = clientID else {
                print("[Sabil SDK]: clientID must not be nil.")
                onCompletion?(nil)
                return
            }
            guard let url = URL(string: urlString) else {
                onCompletion?(nil)
                return
            }
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
                    onCompletion?(data)
                    return
                }
                onCompletion?(data)
            }
            task.resume()
        } catch {
            print("[Sabil SDK]: \(error)")
            onCompletion?(nil)
            return
        }
    }

    fileprivate func showBlockingDialog() {
        self.viewModel.detachLoading = true
        if (self.window == nil) {
            self.window = UIWindow(frame: UIScreen.main.bounds)
        }
        self.window?.rootViewController = self.rootVC
        self.rootVC.view.backgroundColor = .clear
        self.window?.makeKeyAndVisible()
        let dialogView = DialogView(viewModel: self.viewModel) { usageSet in
            for usage in usageSet {
                self.detach(usage: usage)
            }
        }
        let dialogViewContoller = UIHostingController(rootView: dialogView)
        dialogViewContoller.isModalInPresentation = true
        self.rootVC.present(dialogViewContoller, animated: true)
        self.getUserAttachedDevices()
        self.viewModel.detachLoading = false
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
            guard attachResponse.attachedDevices > self.viewModel.limitConfig.overallLimit else {
                return
            }
            DispatchQueue.main.async {
                self.onLimitExceeded?(attachResponse.attachedDevices)
            }
            guard self.appearanceConfig.showBlockingDialog else {
                return
            }

            DispatchQueue.main.async {
                self.showBlockingDialog()
            }
        }
    }

    fileprivate func getDeviceInfo() -> [String: Any] {
        return [
            "os": ["name": UIDevice.current.systemName, "version": UIDevice.current.systemVersion],
            "device": [
                "vendor": "Apple",
                "model": UIDevice.current.model,
                "type": deviceType().rawValue]]
    }

    fileprivate func deviceType() -> SabilDeviceType {
        return UIDevice.current.model.contains("iPad") ? .tablet : .mobile
    }

    /**
     * Detaches the devices from the user device list.
     *
     * Call this function only when the device is no longer attached to the user. A common place to call this function is the logout sequence. You should not call this function anywhere else unless you are an advancer user and you know what you're doing.
     */
    public func detach(usage: SabilDeviceUsage) {
        detach(deviceID: usage.deviceID) { response in
            guard response?.success == true else {
                return
            }
            DispatchQueue.main.async {
                self.viewModel.attachedDevices.removeAll(where: {$0.id == usage.id})

                guard usage.deviceID != self.getDeviceID() else {
                    self.onLogoutCurrentDevice?(usage)
                    self.hideBlockingDialog()
                    return
                }
                self.onLogoutOtherDevice?(usage)
                if self.viewModel.attachedDevices.count <= self.viewModel.limitConfig.overallLimit {
                    self.hideBlockingDialog()
                }
            }
        }
    }

    public func detach(deviceID device: String, completion: ((SabilAttachResponse?) -> Void)? = nil) {
        guard let userID = userID else {
            print("[Sabil SDK]: userID must not be nil.")
            completion?(nil)
            return
        }
        let body = [
            "device_id": device,
            "user": userID
        ]
        httpRequest(method: "POST", url: "\(baseURL)/usage/detach", body: body) { data in
            guard let data = data else { return }
            let decoder = JSONDecoder()
            do {
                completion?(try decoder.decode(SabilAttachResponse.self, from: data))
            } catch {
                print("[Sabil SDK]: \(error)")
                completion?(nil)
            }
        }
    }

    fileprivate func hideBlockingDialog() {
        self.rootVC.dismiss(animated: true)
        self.window?.resignKey()
        self.window = nil
    }

    /**
     * Returns the devices currently attached to the user.
     */
    public func getUserAttachedDevices() {
        guard let userID = userID else {
            print("[Sabil SDK]: userID must not be nil.")
            return
        }
        self.viewModel.loadingDevices = true
        httpRequest(method: "GET", url: "\(baseURL)/usage/\(userID)/attached_devices") { data in
            DispatchQueue.main.async {
                self.viewModel.loadingDevices = false
            }

            guard let data = data else { return }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(.iso8601Full)
            do {
                let devices = try decoder.decode([SabilDeviceUsage].self, from: data)
                DispatchQueue.main.async {
                    self.viewModel.attachedDevices = devices
                }
            } catch {
                print("[Sabil SDK]: \(error)")
            }
        }
    }
}


