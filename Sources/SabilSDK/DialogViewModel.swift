//
//  File.swift
//  
//
//  Created by Ahmed Saleh on 7/11/22.
//

import Foundation

final class DialogViewModel: ObservableObject {
    @Published var currentDeviceID: String
    @Published var attachedDevices: [SabilDeviceUsage] = []
    @Published var loadingDevices: Bool = false
    @Published var limitConfig: SabilLimitConfig

    init(currentDeviceID: String, attachedDevices: [SabilDeviceUsage], limitConfig: SabilLimitConfig, loadingDevices: Bool) {
        self.currentDeviceID = currentDeviceID
        self.attachedDevices = attachedDevices
        self.loadingDevices = loadingDevices
        self.limitConfig = limitConfig
    }
}
