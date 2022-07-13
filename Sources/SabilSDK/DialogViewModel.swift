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
    @Published var limitConfig: SabilLimitConfig
    @Published var loadingDevices: Bool = false
    @Published var detachLoading: Bool = false

    init(currentDeviceID: String, attachedDevices: [SabilDeviceUsage], limitConfig: SabilLimitConfig) {
        self.currentDeviceID = currentDeviceID
        self.attachedDevices = attachedDevices
        self.limitConfig = limitConfig
    }
}
