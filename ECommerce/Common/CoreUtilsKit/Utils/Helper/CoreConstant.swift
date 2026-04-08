
//  Constants.swift
//  MyKiot
//
//  Created by Nguyen Duc Hung on 3/6/25.
//

import Foundation

// MARK: - Notification Names

extension Foundation.Notification.Name {
    static let newPushNotificationReceived = Foundation.Notification.Name(rawValue: "newPushNotificationReceived")
}

enum Constants {

    // MARK: - UserDefaults Keys
    
    enum UserDefaultsKey {
        static let isUserLoggedIn = "isLogin"
        
        // Session keys
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let expiresAt = "expires_at"
        
        // Legacy token key (for backward compatibility)
        static let authToken = "auth_token"
        
        // User keys
        static let userId = "user_id"
        static let userName = "user_name"
        static let userEmail = "user_email"
        static let userPhone = "user_phone"
        static let userAvatarURL = "user_avatar_url"
        static let isPhoneVerified = "is_phone_verified"
        static let orderCount = "order_count"
        static let memberSinceDays = "member_since_days"
        
        // Location cache keys
        static let cachedLatitude = "cached_latitude"
        static let cachedLongitude = "cached_longitude"
        static let cachedAddress = "cached_address"
        static let cachedAddressDetail = "cached_address_detail"
        static let cachedProvinceId = "cached_province_id"
        static let cachedDistrictId = "cached_district_id"
        static let cachedWardId = "cached_ward_id"
        static let cachedCountryId = "cached_country_id"
        static let cachedContactPersonName = "cached_contact_person_name"
        static let cachedContactPersonNumber = "cached_contact_person_number"
        static let cachedAddressType = "cached_address_type"
        static let cachedAddressId = "cached_address_id"
        
        // Device token key
        static let deviceToken = "device_token"
        
        // Push notification permission requested key
        static let pushNotificationPermissionRequested = "push_notification_permission_requested"
    }

    // MARK: - Language
    
    static func getLanguage() -> String {
        let languageCode = Locale.current.languageCode
        if languageCode == "vi" || languageCode == "vi-VN" {
            return "vi"
        }
        return "vi" // fallback vẫn là "vi"
    }
}

