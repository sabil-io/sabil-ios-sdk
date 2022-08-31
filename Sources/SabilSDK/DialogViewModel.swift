//
//  File.swift
//  
//
//  Created by Ahmed Saleh on 7/11/22.
//

import Foundation

final class DialogViewModel: ObservableObject {
    @Published var currentDeviceID: String
    @Published var attachedDevices: [SabilDevice] = []
    @Published var limitConfig: SabilLimitConfig?
    @Published var loadingDevices: Bool = false
    @Published var detachLoading: Bool = false
    @Published var defaultDeviceLimit: Int = 0

    init(currentDeviceID: String, attachedDevices: [SabilDevice], limitConfig: SabilLimitConfig?) {
        self.currentDeviceID = currentDeviceID
        self.attachedDevices = attachedDevices
        self.limitConfig = limitConfig
    }
}
