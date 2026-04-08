//
//  UIViewController+Window.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit
import Contacts

@objc
extension UIViewController {

	func requestContactPermission(completion: ((_ accessGranted: Bool) -> Void)? = nil) {
        CNContactStore().requestAccess(for: .contacts) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    completion?(true)
                }
            } else {
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }

    func openAppSetting() {
        if let appSettingsURL = URL(string: UIApplication.openSettingsURLString) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(appSettingsURL, options: [:], completionHandler: nil)
            } else {
                
                UIApplication.shared.openURL(appSettingsURL)
            }
        }
    }
}

