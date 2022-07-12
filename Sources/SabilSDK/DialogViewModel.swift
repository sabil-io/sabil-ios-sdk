//
//  File.swift
//  
//
//  Created by Ahmed Saleh on 7/11/22.
//

import Foundation

final class DialogViewModel: ObservableObject {
    @Published var attachedDevices: [SabilDeviceUsage] = []
    @Published var loadingDevices: Bool = false
}
