//
//  Utilities.swift
//  MyKiot
//
//  Created by Nguyen Duc Hung on 3/6/25.
//

import Foundation

class Utilities: NSObject {
    
    let defaults = UserDefaults.standard
    
    // MARK: - Login State
    
    /// Set User login state
    func saveLogging(_ isLogin: Bool) {
        print("💾 [Utilities] Saving login state:")
        print("   - Is Logged In: \(isLogin) -> Key: \(Constants.UserDefaultsKey.isUserLoggedIn)")
        defaults.set(isLogin, forKey: Constants.UserDefaultsKey.isUserLoggedIn)
        
        // Verify saved value
        let savedLoginState = defaults.bool(forKey: Constants.UserDefaultsKey.isUserLoggedIn)
        print("✅ [Utilities] Login state saved - Verification: \(savedLoginState)")
    }
    
    /// Get User login state
    func isLoggedIn() -> Bool {
        return defaults.bool(forKey: Constants.UserDefaultsKey.isUserLoggedIn)
    }
    
    // MARK: - Session Management (Keychain Only)
    
    /// Save session info (accessToken, refreshToken, expiresAt) to Keychain
    /// Note: Tokens are ONLY stored in Keychain, not in UserDefaults
    func saveSession(accessToken: String, refreshToken: String, expiresAt: Date) {
        print("💾 [Utilities] Saving session to Keychain:")
        print("   - Access Token Key: \(Constants.UserDefaultsKey.accessToken)")
        print("   - Refresh Token Key: \(Constants.UserDefaultsKey.refreshToken)")
        print("   - Expires At Key: \(Constants.UserDefaultsKey.expiresAt)")
        print("   - Expires At Value: \(expiresAt)")
        
        do {
            // Save tokens to Keychain
            try KeychainHelper.save(accessToken, forKey: Constants.UserDefaultsKey.accessToken)
            try KeychainHelper.save(refreshToken, forKey: Constants.UserDefaultsKey.refreshToken)
            try KeychainHelper.saveDate(expiresAt, forKey: Constants.UserDefaultsKey.expiresAt)
            
            print("✅ [Utilities] Session saved to Keychain successfully")
            
            // Verify saved values
            let savedAccessToken = try KeychainHelper.get(Constants.UserDefaultsKey.accessToken)
            let savedRefreshToken = try KeychainHelper.get(Constants.UserDefaultsKey.refreshToken)
            let savedExpiresAt = try KeychainHelper.getDate(Constants.UserDefaultsKey.expiresAt)
            
            print("✅ [Utilities] Session saved - Verification:")
            print("   - Access Token saved: \(savedAccessToken != nil ? "YES (\(savedAccessToken!.prefix(20))...)" : "NO")")
            print("   - Refresh Token saved: \(savedRefreshToken != nil ? "YES (\(savedRefreshToken!.prefix(20))...)" : "NO")")
            print("   - Expires At saved: \(savedExpiresAt != nil ? "YES (\(savedExpiresAt!))" : "NO")")
        } catch {
            print("❌ [Utilities] Failed to save session to Keychain:")
            print("   - Error: \(error.localizedDescription)")
            assertionFailure("Failed to save session to Keychain: \(error.localizedDescription)")
        }
    }
    
    /// Get access token from Keychain
    /// Note: Tokens are ONLY read from Keychain, not from UserDefaults
    func getAccessToken() -> String? {
        do {
            return try KeychainHelper.get(Constants.UserDefaultsKey.accessToken)
        } catch {
            print("❌ [Utilities] Failed to get access token from Keychain:")
            print("   - Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get refresh token from Keychain
    /// Note: Tokens are ONLY read from Keychain, not from UserDefaults
    func getRefreshToken() -> String? {
        do {
            return try KeychainHelper.get(Constants.UserDefaultsKey.refreshToken)
        } catch {
            print("❌ [Utilities] Failed to get refresh token from Keychain:")
            print("   - Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get expires at date from Keychain
    /// Note: Tokens are ONLY read from Keychain, not from UserDefaults
    func getExpiresAt() -> Date? {
        do {
            return try KeychainHelper.getDate(Constants.UserDefaultsKey.expiresAt)
        } catch {
            print("❌ [Utilities] Failed to get expires at from Keychain:")
            print("   - Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Check if session is expired
    func isSessionExpired() -> Bool {
        guard let expiresAt = getExpiresAt() else {
            return true
        }
        let now = Date()
        let isExpired = now >= expiresAt
        
        if isExpired {
            print("⚠️ [Utilities] Session is expired:")
            print("   - Current time: \(now)")
            print("   - Expires at: \(expiresAt)")
        }
        
        return isExpired
    }
    
    /// Clear session data from Keychain (for logout or refresh)
    func clearSession() {
        print("🗑️ [Utilities] Clearing session from Keychain...")
        
        let accessTokenDeleted = KeychainHelper.delete(Constants.UserDefaultsKey.accessToken)
        let refreshTokenDeleted = KeychainHelper.delete(Constants.UserDefaultsKey.refreshToken)
        let expiresAtDeleted = KeychainHelper.delete(Constants.UserDefaultsKey.expiresAt)
        
        print("✅ [Utilities] Session cleared from Keychain:")
        print("   - Access Token deleted: \(accessTokenDeleted ? "YES" : "NO")")
        print("   - Refresh Token deleted: \(refreshTokenDeleted ? "YES" : "NO")")
        print("   - Expires At deleted: \(expiresAtDeleted ? "YES" : "NO")")
    }
    
    // MARK: - User Info Management
    
    /// Save user info
    func saveUser(user: User) {
        print("💾 [Utilities] Saving user info to UserDefaults:")
        print("   - User ID: \(user.id) -> Key: \(Constants.UserDefaultsKey.userId)")
        print("   - Full Name: \(user.fullName) -> Key: \(Constants.UserDefaultsKey.userName)")
        print("   - Email: \(user.email) -> Key: \(Constants.UserDefaultsKey.userEmail)")
        print("   - Phone: \(user.phone) -> Key: \(Constants.UserDefaultsKey.userPhone)")
        print("   - Avatar URL: \(user.avatarURL?.absoluteString ?? "nil") -> Key: \(Constants.UserDefaultsKey.userAvatarURL)")
        print("   - Order Count: \(user.orderCount) -> Key: \(Constants.UserDefaultsKey.orderCount)")
        print("   - Member Since Days: \(user.memberSinceDays) -> Key: \(Constants.UserDefaultsKey.memberSinceDays)")
        
        defaults.set(user.id, forKey: Constants.UserDefaultsKey.userId)
        defaults.set(user.fullName, forKey: Constants.UserDefaultsKey.userName)
        defaults.set(user.email, forKey: Constants.UserDefaultsKey.userEmail)
        defaults.set(user.phone, forKey: Constants.UserDefaultsKey.userPhone)
        defaults.set(user.avatarURL?.absoluteString, forKey: Constants.UserDefaultsKey.userAvatarURL)
        defaults.set(user.orderCount, forKey: Constants.UserDefaultsKey.orderCount)
        defaults.set(user.memberSinceDays, forKey: Constants.UserDefaultsKey.memberSinceDays)
        
        // Verify saved values
        let savedUserId = defaults.integer(forKey: Constants.UserDefaultsKey.userId)
        let savedUserName = defaults.string(forKey: Constants.UserDefaultsKey.userName)
        let savedUserEmail = defaults.string(forKey: Constants.UserDefaultsKey.userEmail)
        let savedUserPhone = defaults.string(forKey: Constants.UserDefaultsKey.userPhone)
        
        print("✅ [Utilities] User info saved - Verification:")
        print("   - User ID saved: \(savedUserId > 0 ? "YES (\(savedUserId))" : "NO")")
        print("   - Full Name saved: \(savedUserName != nil ? "YES (\(savedUserName!))" : "NO")")
        print("   - Email saved: \(savedUserEmail != nil ? "YES (\(savedUserEmail!))" : "NO")")
        print("   - Phone saved: \(savedUserPhone != nil ? "YES (\(savedUserPhone!))" : "NO")")
    }
    
    /// Get user ID
    func getUserId() -> Int? {
        let userId = defaults.integer(forKey: Constants.UserDefaultsKey.userId)
        return userId > 0 ? userId : nil
    }
    
    /// Get user full name
    func getUserFullName() -> String? {
        return defaults.string(forKey: Constants.UserDefaultsKey.userName)
    }
    
    /// Get user email
    func getUserEmail() -> String? {
        return defaults.string(forKey: Constants.UserDefaultsKey.userEmail)
    }
    
    /// Get user phone
    func getUserPhone() -> String? {
        return defaults.string(forKey: Constants.UserDefaultsKey.userPhone)
    }
    
    /// Get user avatar URL
    func getUserAvatarURL() -> URL? {
        guard let urlString = defaults.string(forKey: Constants.UserDefaultsKey.userAvatarURL) else {
            return nil
        }
        return URL(string: urlString)
    }
    
    /// Get user info as User object
    func getUserInfo() -> User? {
        guard let id = getUserId(),
              let fullName = getUserFullName(),
              let email = getUserEmail(),
              let phone = getUserPhone() else {
            return nil
        }
        return User(
            id: id,
            fullName: fullName,
            email: email,
            phone: phone,
            avatarURL: getUserAvatarURL(),
            bankAccount: [],
            orderCount: defaults.integer(forKey: Constants.UserDefaultsKey.orderCount),
            memberSinceDays: defaults.integer(forKey: Constants.UserDefaultsKey.memberSinceDays),
            createdAt: nil
        )
    }
    
    // MARK: - Legacy Support (for backward compatibility)
    
    /// Get auth token (legacy - returns accessToken)
    func getAuthToken() -> String? {
        return getAccessToken()
    }
    
    // MARK: - Logout
    
    /// Clear all user info and logout
    func logout() {
        print("========== LOGOUT - CLEARING DATA ==========")
        
        // Log current values before clearing
        print("📋 Current stored data before logout:")
        print("   - Is Logged In: \(defaults.bool(forKey: Constants.UserDefaultsKey.isUserLoggedIn))")
        
        // Check Keychain tokens
        let accessTokenExists = (try? KeychainHelper.get(Constants.UserDefaultsKey.accessToken)) != nil
        let refreshTokenExists = (try? KeychainHelper.get(Constants.UserDefaultsKey.refreshToken)) != nil
        let expiresAtExists = (try? KeychainHelper.getDate(Constants.UserDefaultsKey.expiresAt)) != nil
        print("   - Access Token (Keychain): \(accessTokenExists ? "EXISTS" : "nil")")
        print("   - Refresh Token (Keychain): \(refreshTokenExists ? "EXISTS" : "nil")")
        print("   - Expires At (Keychain): \(expiresAtExists ? "EXISTS" : "nil")")
        print("   - User ID: \(defaults.integer(forKey: Constants.UserDefaultsKey.userId))")
        print("   - User Name: \(defaults.string(forKey: Constants.UserDefaultsKey.userName) ?? "nil")")
        print("   - User Email: \(defaults.string(forKey: Constants.UserDefaultsKey.userEmail) ?? "nil")")
        print("   - User Phone: \(defaults.string(forKey: Constants.UserDefaultsKey.userPhone) ?? "nil")")
        
        // QUAN TRỌNG: Clear TokenRefreshService state TRƯỚC khi clear session
        // Điều này ngăn chặn TokenRefreshService cố refresh token cũ sau khi logout
        print("🔄 Resetting TokenRefreshService...")
        TokenRefreshService.shared.reset()
        
        // Clear login state FIRST (trước khi clear session)
        // Điều này đảm bảo các request sau sẽ biết user đã logout
        print("🗑️ Clearing login state...")
        saveLogging(false)
        
        // Clear session from Keychain
        clearSession()
        
        // Clear user info
        print("🗑️ Clearing user info...")
        defaults.removeObject(forKey: Constants.UserDefaultsKey.userId)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.userName)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.userEmail)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.userPhone)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.userAvatarURL)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.orderCount)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.memberSinceDays)
        print("   ✅ Removed: userId, userName, userEmail, userPhone, userAvatarURL, orderCount, memberSinceDays")
        
        // Legacy support
        defaults.removeObject(forKey: Constants.UserDefaultsKey.authToken)
        print("   ✅ Removed: authToken (legacy)")
        
        // Verify all cleared
        print("✅ Logout completed - Verification:")
        print("   - Is Logged In: \(defaults.bool(forKey: Constants.UserDefaultsKey.isUserLoggedIn))")
        
        // Verify Keychain tokens are cleared
        let accessTokenStillExists = (try? KeychainHelper.get(Constants.UserDefaultsKey.accessToken)) != nil
        let refreshTokenStillExists = (try? KeychainHelper.get(Constants.UserDefaultsKey.refreshToken)) != nil
        print("   - Access Token (Keychain): \(accessTokenStillExists ? "STILL EXISTS ❌" : "CLEARED ✅")")
        print("   - Refresh Token (Keychain): \(refreshTokenStillExists ? "STILL EXISTS ❌" : "CLEARED ✅")")
        print("   - User ID: \(defaults.integer(forKey: Constants.UserDefaultsKey.userId) > 0 ? "STILL EXISTS ❌" : "CLEARED ✅")")
        print("============================================")
    }
    
    // MARK: - Location Cache Management
    
    /// Save full location/address information to cache
    /// Note: Uses addressDetail as primary address field (more accurate than address)
    func saveLocation(address: Address) {
        print("💾 [Utilities] Saving location to cache:")
        print("   - Address ID: \(address.id)")
        print("   - Address Detail: \(address.addressDetail)")
        print("   - Full Address: \(address.address)")
        print("   - Province ID: \(address.provinceId)")
        print("   - District ID: \(address.districtId)")
        print("   - Ward ID: \(address.wardId)")
        print("   - Country ID: \(address.countryId)")
        print("   - Contact Person: \(address.contactPersonName)")
        print("   - Contact Number: \(address.contactPersonNumber)")
        print("   - Address Type: \(address.addressType)")
        print("   - Latitude: \(address.latitude)")
        print("   - Longitude: \(address.longitude)")
        
        // Save all address information
        defaults.set(address.id, forKey: Constants.UserDefaultsKey.cachedAddressId)
        defaults.set(address.addressDetail, forKey: Constants.UserDefaultsKey.cachedAddressDetail)
        defaults.set(address.address, forKey: Constants.UserDefaultsKey.cachedAddress)
        defaults.set(address.provinceId, forKey: Constants.UserDefaultsKey.cachedProvinceId)
        defaults.set(address.districtId, forKey: Constants.UserDefaultsKey.cachedDistrictId)
        defaults.set(address.wardId, forKey: Constants.UserDefaultsKey.cachedWardId)
        defaults.set(address.countryId, forKey: Constants.UserDefaultsKey.cachedCountryId)
        defaults.set(address.contactPersonName, forKey: Constants.UserDefaultsKey.cachedContactPersonName)
        defaults.set(address.contactPersonNumber, forKey: Constants.UserDefaultsKey.cachedContactPersonNumber)
        defaults.set(address.addressType, forKey: Constants.UserDefaultsKey.cachedAddressType)
        defaults.set(address.latitude, forKey: Constants.UserDefaultsKey.cachedLatitude)
        defaults.set(address.longitude, forKey: Constants.UserDefaultsKey.cachedLongitude)
        
        print("✅ [Utilities] Location cache saved successfully")
    }
    
    /// Legacy method: Save location with simple parameters (for backward compatibility)
    /// Note: Use saveLocation(address: Address) for full information
    func saveLocation(address: String, latitude: String, longitude: String) {
        print("💾 [Utilities] Saving location to cache (legacy method):")
        print("   - Address: \(address)")
        print("   - Latitude: \(latitude)")
        print("   - Longitude: \(longitude)")
        defaults.set(address, forKey: Constants.UserDefaultsKey.cachedAddress)
        defaults.set(latitude, forKey: Constants.UserDefaultsKey.cachedLatitude)
        defaults.set(longitude, forKey: Constants.UserDefaultsKey.cachedLongitude)
    }
    
    /// Get cached address ID
    func getCachedAddressId() -> Int? {
        let id = defaults.integer(forKey: Constants.UserDefaultsKey.cachedAddressId)
        return id > 0 ? id : nil
    }
    
    /// Get cached address detail (primary address field)
    func getCachedAddressDetail() -> String? {
        return defaults.string(forKey: Constants.UserDefaultsKey.cachedAddressDetail)
    }
    
    /// Get cached address (legacy - full address string)
    func getCachedAddress() -> String? {
        return defaults.string(forKey: Constants.UserDefaultsKey.cachedAddress)
    }
    
    /// Get cached province ID
    func getCachedProvinceId() -> Int? {
        let id = defaults.integer(forKey: Constants.UserDefaultsKey.cachedProvinceId)
        return id > 0 ? id : nil
    }
    
    /// Get cached district ID
    func getCachedDistrictId() -> Int? {
        let id = defaults.integer(forKey: Constants.UserDefaultsKey.cachedDistrictId)
        return id > 0 ? id : nil
    }
    
    /// Get cached ward ID
    func getCachedWardId() -> Int? {
        let id = defaults.integer(forKey: Constants.UserDefaultsKey.cachedWardId)
        return id > 0 ? id : nil
    }
    
    /// Get cached country ID
    func getCachedCountryId() -> Int? {
        let id = defaults.integer(forKey: Constants.UserDefaultsKey.cachedCountryId)
        return id > 0 ? id : nil
    }
    
    /// Get cached contact person name
    func getCachedContactPersonName() -> String? {
        return defaults.string(forKey: Constants.UserDefaultsKey.cachedContactPersonName)
    }
    
    /// Get cached contact person number
    func getCachedContactPersonNumber() -> String? {
        return defaults.string(forKey: Constants.UserDefaultsKey.cachedContactPersonNumber)
    }
    
    /// Get cached address type
    func getCachedAddressType() -> String? {
        return defaults.string(forKey: Constants.UserDefaultsKey.cachedAddressType)
    }
    
    /// Get cached latitude
    func getCachedLatitude() -> String? {
        return defaults.string(forKey: Constants.UserDefaultsKey.cachedLatitude)
    }
    
    /// Get cached longitude
    func getCachedLongitude() -> String? {
        return defaults.string(forKey: Constants.UserDefaultsKey.cachedLongitude)
    }
    
    /// Check if location cache exists (with full information)
    func hasLocationCache() -> Bool {
        // Check for essential fields: addressDetail or address, and location IDs
        let hasAddress = (getCachedAddressDetail() != nil && !getCachedAddressDetail()!.isEmpty) ||
                         (getCachedAddress() != nil && !getCachedAddress()!.isEmpty)
        let hasLocationIds = getCachedProvinceId() != nil && 
                            getCachedDistrictId() != nil && 
                            getCachedWardId() != nil
        
        return hasAddress && hasLocationIds
    }
    
    /// Clear location cache (all fields)
    func clearLocationCache() {
        defaults.removeObject(forKey: Constants.UserDefaultsKey.cachedAddressId)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.cachedAddressDetail)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.cachedAddress)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.cachedProvinceId)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.cachedDistrictId)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.cachedWardId)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.cachedCountryId)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.cachedContactPersonName)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.cachedContactPersonNumber)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.cachedAddressType)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.cachedLatitude)
        defaults.removeObject(forKey: Constants.UserDefaultsKey.cachedLongitude)
        
        print("🗑️ [Utilities] Location cache cleared")
    }
}

//@objc public static func shouldShowForceUpdate(minVersionSupport: String) -> Bool {
//    let appVersion = HelperFunction.appVersion()
//    if !minVersionSupport.isEmpty && HelperFunction.compareVersions(appVersion, minVersionSupport) == .lessThan {
//        return true
//    } else {
//        return false
//    }
//}
//}
//public let adjustDomain = Bundle.main.bundleIdentifier?.contains("staging") == true ? "vtmoney.go.link/" :
//                          Bundle.main.bundleIdentifier?.contains("uat") == true ? "vtmoneyuat.go.link/" : "viettelmoney.go.link/"
