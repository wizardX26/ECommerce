//
//  LocalAuthenticationContextExtensions.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import LocalAuthentication

public extension LAContext {
    
    enum BiometricType: String {
        case none
        case touchID
        case faceID
    }

    var biometricType: BiometricType {
        var error: NSError?

        guard self.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        if #available(iOS 11.0, *) {
            switch self.biometryType {
                
            case .none:
                return .none
                
            case .touchID:
                return .touchID
                
            case .faceID:
                return .faceID
                
            @unknown default:
                return .none
                
            }
        } else {
            return self.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touchID : .none
        }
    }
}
