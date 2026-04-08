//
//  AccountObject.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import Foundation
import UIKit
import LocalAuthentication

public class HelperFunction {
    
    public static func appVersion(_ bundle: Bundle = .main) -> String {
        let appVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
        return appVersion ?? ""
    }
    
    public static func authenticationWithBiometric(_ completion: @escaping (Bool) -> Void) {
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.localizedFallbackTitle = ""
        var authorizationError: NSError?
        var reason = CoreUtilsKitLocalization.required_touch_id.localized
        
        if LAContext().biometricType == .faceID {
            reason = CoreUtilsKitLocalization.required_face_id.localized
        }
        
        if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authorizationError) {
            localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                completion(success)
            }
        } else {
            completion(false)
        }
    }
    
    public static func getImage(named: String, in bundle: Bundle) -> UIImage? {
        return UIImage(named: named, in: bundle, compatibleWith: nil)
    }
}

// MARK: - Navigation Bars
public extension HelperFunction {
    static func isIPhoneX() -> Bool {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0.0 > 20.0
        }
        
        return false
    }
    
    static func heightNavigationBar() -> CGFloat {
        return isIPhoneX() ? 88.0 : 64.0
    }
    
    static func heightSafeAreaTop() -> CGFloat {
        if #available(iOS 11.0, *) {
            return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 20.0
        }
        
        return 20.0
    }
    
    static func paddingTopWithSafeArea() -> CGFloat {
        return heightNavigationBar() - heightSafeAreaTop()
    }
}

// MARK: Bottomsheet
public extension HelperFunction {
    static func getTwoEdgesRoundCornerLayer(view: UIView, cornerRadius:CGFloat) -> CAShapeLayer {
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath
        return maskLayer
    }
}

// MARK: - Read Json File
public extension HelperFunction {
    static func readJsonFile(_ name: String, bundle: Bundle = Bundle(for: HelperFunction.self)) -> Data? {
        if let path = bundle.path(forResource: name, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                return data
            } catch let error {
                debugPrint("parse error: \(error.localizedDescription)")
                return nil
            }
        }
        debugPrint("Invalid filename/path.")
        return nil
    }
}

// MARK: - UserDefaults
public extension HelperFunction {
    static func getValueFromUserDefault(_ key: String) -> Any? {
        guard let value = UserDefaults.standard.object(forKey: key) else {
            return nil
        }
        return value
    }
    
    static func setValueToUserDefault(_ value: Any?, key: String) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }
}

// MARK: Compare version
public extension HelperFunction {
    enum VersionComparisonResult {
        case equal
        case greaterThan
        case lessThan
    }

    static func compareVersions(_ version1: String, _ version2: String) -> VersionComparisonResult {
        let version1Components = version1.split(separator: ".").compactMap { Int($0) }
        let version2Components = version2.split(separator: ".").compactMap { Int($0) }
        
        for index in 0..<min(version1Components.count, version2Components.count) {
            if version1Components[index] > version2Components[index] {
                return .greaterThan
            } else if version1Components[index] < version2Components[index] {
                return .lessThan
            }
        }
        
        if version1Components.count == version2Components.count {
            return .equal
        } else if version1Components.count > version2Components.count {
            return .greaterThan
        } else {
            return .lessThan
        }
    }
}

// MARK: Date and time
public extension HelperFunction {
    private static var dateFormatter: DateFormatter {
        let inputFormatter = DateFormatter()
        inputFormatter.locale = Locale(identifier: "vi_VN")
        inputFormatter.timeZone = TimeZone(secondsFromGMT: 7 * 3600)
        return inputFormatter
    }

    static func convertToDate(_ dateString: String, format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        let dateFormatter = dateFormatter
        dateFormatter.dateFormat = format
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        let date = dateFormatter.date(from: dateString)
        return date
    }

    static func isDateValid(date: Date, startDate: Date?, endDate: Date?) -> Bool {
        var isValid = true
        if let startDate = startDate {
            isValid = startDate.compare(date) == .orderedSame || startDate.compare(date) == .orderedAscending
        }
        if let endDate = endDate {
            isValid = isValid && (date.compare(endDate) == .orderedSame || date.compare(endDate) == .orderedAscending)
        }
        
        return isValid
    }
    
    static func currentDate(format: String) -> Date? {
        let dateFormatter = dateFormatter
        dateFormatter.dateFormat = format
        let dateString = dateFormatter.string(from: Date())
        let formattedDate = dateFormatter.date(from: dateString)
        return formattedDate
    }
    
    static func currentDateString(format: String) -> String {
        let dateFormatter = dateFormatter
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: Date())
    }
    
    static func convertDateString(_ dateString: String, from inputFormat: String, to outputFormat: String) -> String {
        let inputFormatter = dateFormatter
        inputFormatter.dateFormat = inputFormat
        let outputFormatter = dateFormatter
        outputFormatter.dateFormat = outputFormat
        
        if let date = inputFormatter.date(from: dateString) {
            let formattedDateString = outputFormatter.string(from: date)
            return formattedDateString
        } else {
            return ""
        }
    }
    
    static func convertDateToString(_ date: Date, withFormat dateFormat: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "GMT+7")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = dateFormat
        return formatter.string(from: date)
    }
}
