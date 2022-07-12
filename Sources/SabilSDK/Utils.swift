//
//  File.swift
//  
//
//  Created by Ahmed Saleh on 7/11/22.
//

import Foundation
import UIKit

@available(iOS 13.0, *)
func topmostViewController() -> UIViewController? {
    var rootVC: UIViewController?
    for scene in UIApplication.shared.connectedScenes {
        if scene.activationState == .foregroundActive {
            if let vc = (scene.delegate as? UIWindowSceneDelegate)?.window??.rootViewController {
                rootVC = vc
                break
            }
        }
    }
    var presentedVC = rootVC
    while presentedVC?.presentedViewController != nil {
        presentedVC = presentedVC?.presentedViewController
    }
    return presentedVC
}
