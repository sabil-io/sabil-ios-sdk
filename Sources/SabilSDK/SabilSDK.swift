import Foundation
import UIKit
import SwiftUI
import LDSwiftEventSource

public final class Sabil {
    public static let shared = Sabil()

    private var eventSource: EventSource?
    public var clientID: String?
    public var secret: String?
    public var userID: String?
    public var appearanceConfig: SabilAppearanceConfig?
    private let baseURL = "https://api.sabil.io"
    private var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    private let rootVC = UIViewController()
    private let viewModel = DialogViewModel(currentDeviceID: "",
                                            attachedDevices: [],
                                            limitConfig: nil)
    /**
     * The unique device id generated and tracked by Sabil. It will be null until the first attach call.
     */
    public private(set) var deviceID: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: "sabil_device_id")
            self.viewModel.currentDeviceID = newValue ?? ""
        }
        get {
            return UserDefaults.standard.string(forKey: "sabil_device_id")
        }
    }

    /// Called when the number of attached devices for  the user exceed the allotted limit.
    public var onLimitExceeded: ((Int) -> Void)?

    /**
     * Called when the user chooses to log out of the current device.
     *
     * This function will be called immediately after the user detaches the current device from the list of active devices.
     * The user can then continue using the app until the next attach.
     * It is **strongly recommended** that you log the user out when this function fires.
     */
    public var onLogoutCurrentDevice: ((SabilDevice?) -> Void)? {
        didSet {
            listenToRealtimeEvents()
        }
    }

    /**
     * Called when the user chooses to log out a remote device (as apposed to this device).
     *
     * This function will be called immeditely after the user detaches the current device from the list of active devices.
     * The user can then continue using the app until the next attach.
     * It is **strongly recommended** that you log the user out when this function fires.
     */
    public var onLogoutOtherDevice: ((SabilDevice) -> Void)?

    public func config(clientID: String, secret: String? = nil, appearanceConfig: SabilAppearanceConfig? = nil, limitConfig: SabilLimitConfig? = nil) {
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

    private func getDeviceIDForVendor() -> String {
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
        let dialogView = DialogView(viewModel: self.viewModel) { devices in
            for device in devices {
                self.detach(device: device)
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
        let body: [String : Any] = ["user": userID, "device_info": deviceInfo, "signals": ["iosVendorIdentifier": getDeviceIDForVendor()]]
        httpRequest(method: "POST", url: "\(baseURL)/v2/access", body: body) { data in

            guard let data = data else { return }
            let decoder = JSONDecoder()
            guard let attachResponse = try? decoder.decode(SabilAttachResponse.self, from: data) else { return }
            self.deviceID = attachResponse.deviceID
            guard let limit = self.viewModel.limitConfig?.overallLimit ?? attachResponse.defaultDeviceLimit else {
                return
            }
            DispatchQueue.main.async {
                self.viewModel.defaultDeviceLimit = limit
            }
            guard attachResponse.attachedDevices > limit else {
                return
            }
            DispatchQueue.main.async {
                self.onLimitExceeded?(attachResponse.attachedDevices)
            }
            guard self.appearanceConfig?.showBlockingDialog ?? attachResponse.blockOverUsage ?? false else {
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
    public func detach(device: SabilDevice) {
        detach(deviceID: device.id) { response in
            guard response?.success == true else {
                return
            }
            DispatchQueue.main.async {
                self.viewModel.attachedDevices.removeAll(where: {$0.id == device.id})
                self.viewModel.defaultDeviceLimit = response?.defaultDeviceLimit ?? self.viewModel.defaultDeviceLimit

                if device.id != self.deviceID {
                    self.onLogoutOtherDevice?(device)
                }

                if let limit = self.viewModel.limitConfig?.overallLimit ?? response?.defaultDeviceLimit, self.viewModel.attachedDevices.count <= limit {
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
            "device": device,
            "user": userID
        ]
        httpRequest(method: "POST", url: "\(baseURL)/v2/access/detach", body: body) { data in
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
        httpRequest(method: "GET", url: "\(baseURL)/v2/access/user/\(userID)/attached_devices") { data in
            DispatchQueue.main.async {
                self.viewModel.loadingDevices = false
            }

            guard let data = data else { return }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(.iso8601Full)
            do {
                let devices = try decoder.decode([SabilDevice].self, from: data)
                DispatchQueue.main.async {
                    self.viewModel.attachedDevices = devices
                }
            } catch {
                print("[Sabil SDK]: \(error)")
            }
        }
    }
}


extension Sabil: EventHandler {

    func listenToRealtimeEvents() {
        if let clientID = clientID, let device = deviceID, let url = URL(string: "\(baseURL)/v2/access/device/\(device)/listen?auth=Basic \(clientID):\(secret ?? "")".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            eventSource?.stop()
            eventSource = EventSource(config: EventSource.Config(handler: self, url: url))
            eventSource?.start()
        }
    }

    public func onOpened() {
        // left empty on purpose
    }

    public func onClosed() {
        // left empty on purpose
    }

    public func onMessage(eventType: String, messageEvent: LDSwiftEventSource.MessageEvent) {
        if messageEvent.data == "\"logout\"" {
            DispatchQueue.main.async {
                self.onLogoutCurrentDevice?(self.viewModel.attachedDevices.first(where: {$0.id == self.deviceID}))
                self.hideBlockingDialog()
            }

        }
    }

    public func onComment(comment: String) {
        // left empty on purpose
    }

    public func onError(error: Error) {
        // left empty on purpose
    }


}
