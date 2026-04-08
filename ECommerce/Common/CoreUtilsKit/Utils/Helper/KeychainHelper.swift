//
//  KeychainHelper.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/1/26.
//

import Foundation
import Security

/// Helper class for Keychain operations
/// Provides secure storage for sensitive data like tokens
final class KeychainHelper {
    
    // Service name - unique identifier for the app
    private static let service = "co.wizard.architect.ECommerce"
    
    // MARK: - Save String to Keychain
    
    /// Save a string value to Keychain
    /// - Parameters:
    ///   - value: The string value to save
    ///   - key: The key (account name) to identify the item
    /// - Throws: KeychainError if operation fails
    static func save(_ value: String, forKey key: String) throws {
        print("🔐 [KeychainHelper] Attempting to save to Keychain:")
        print("   - Key: \(key)")
        print("   - Value length: \(value.count) characters")
        
        // Step 1: Convert String to Data (Keychain only accepts Data)
        guard let data = value.data(using: .utf8) else {
            print("❌ [KeychainHelper] Failed to convert String to Data")
            throw KeychainError.invalidData
        }
        
        // Step 2: Delete existing item first (to avoid conflicts)
        delete(key) // Ignore error if not exists
        
        // Step 3: Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            // WhenUnlocked = Persist even after uninstall (for backup/restore)
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Step 4: Add item to Keychain using Security API
        let status = SecItemAdd(query as CFDictionary, nil)
        
        // Step 5: Check result
        if status == errSecSuccess {
            print("✅ [KeychainHelper] Successfully saved to Keychain:")
            print("   - Key: \(key)")
            print("   - Status: \(status) (errSecSuccess)")
        } else {
            let errorMessage = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
            print("❌ [KeychainHelper] Failed to save to Keychain:")
            print("   - Key: \(key)")
            print("   - Status: \(status)")
            print("   - Error: \(errorMessage)")
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Retrieve String from Keychain
    
    /// Retrieve a string value from Keychain
    /// - Parameter key: The key (account name) to identify the item
    /// - Returns: The string value if found, nil if not found
    /// - Throws: KeychainError if operation fails
    static func get(_ key: String) throws -> String? {
        print("🔐 [KeychainHelper] Attempting to retrieve from Keychain:")
        print("   - Key: \(key)")
        
        // Step 1: Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        // Step 2: Variable to receive result
        var result: AnyObject?
        
        // Step 3: Search Keychain using Security API
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // Step 4: Handle result
        switch status {
        case errSecSuccess:
            // Found → Convert Data to String
            guard let data = result as? Data,
                  let value = String(data: data, encoding: .utf8) else {
                print("❌ [KeychainHelper] Failed to convert Data to String")
                throw KeychainError.invalidData
            }
            print("✅ [KeychainHelper] Successfully retrieved from Keychain:")
            print("   - Key: \(key)")
            print("   - Value length: \(value.count) characters")
            print("   - Value prefix: \(value.prefix(20))...")
            return value
            
        case errSecItemNotFound:
            // Not found → return nil
            print("⚠️ [KeychainHelper] Item not found in Keychain:")
            print("   - Key: \(key)")
            print("   - Status: \(status) (errSecItemNotFound)")
            return nil
            
        default:
            // Other error → throw
            let errorMessage = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
            print("❌ [KeychainHelper] Failed to retrieve from Keychain:")
            print("   - Key: \(key)")
            print("   - Status: \(status)")
            print("   - Error: \(errorMessage)")
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Delete from Keychain
    
    /// Delete an item from Keychain
    /// - Parameter key: The key (account name) to identify the item
    /// - Returns: true if deleted successfully or not found, false if error
    @discardableResult
    static func delete(_ key: String) -> Bool {
        print("🔐 [KeychainHelper] Attempting to delete from Keychain:")
        print("   - Key: \(key)")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("✅ [KeychainHelper] Successfully deleted from Keychain:")
            print("   - Key: \(key)")
            return true
        } else if status == errSecItemNotFound {
            print("⚠️ [KeychainHelper] Item not found in Keychain (already deleted):")
            print("   - Key: \(key)")
            return true // Considered success if not found
        } else {
            let errorMessage = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
            print("❌ [KeychainHelper] Failed to delete from Keychain:")
            print("   - Key: \(key)")
            print("   - Status: \(status)")
            print("   - Error: \(errorMessage)")
            return false
        }
    }
    
    // MARK: - Delete All (for logout)
    
    /// Delete all items for this service from Keychain
    static func deleteAll() {
        print("🔐 [KeychainHelper] Attempting to delete all items from Keychain:")
        print("   - Service: \(service)")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("✅ [KeychainHelper] Successfully deleted all items from Keychain")
        } else {
            let errorMessage = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
            print("❌ [KeychainHelper] Failed to delete all items from Keychain:")
            print("   - Status: \(status)")
            print("   - Error: \(errorMessage)")
        }
    }
}

// MARK: - Date Extension

extension KeychainHelper {
    
    /// Save Date to Keychain (converts to TimeInterval string)
    /// - Parameters:
    ///   - date: The Date to save
    ///   - key: The key (account name) to identify the item
    /// - Throws: KeychainError if operation fails
    static func saveDate(_ date: Date, forKey key: String) throws {
        let timeInterval = date.timeIntervalSince1970
        print("🔐 [KeychainHelper] Saving Date to Keychain:")
        print("   - Key: \(key)")
        print("   - Date: \(date)")
        print("   - TimeInterval: \(timeInterval)")
        try save(String(timeInterval), forKey: key)
    }
    
    /// Retrieve Date from Keychain (converts from TimeInterval string)
    /// - Parameter key: The key (account name) to identify the item
    /// - Returns: The Date if found, nil if not found
    /// - Throws: KeychainError if operation fails
    static func getDate(_ key: String) throws -> Date? {
        guard let timeIntervalString = try get(key),
              let timeInterval = TimeInterval(timeIntervalString) else {
            return nil
        }
        let date = Date(timeIntervalSince1970: timeInterval)
        print("🔐 [KeychainHelper] Retrieved Date from Keychain:")
        print("   - Key: \(key)")
        print("   - Date: \(date)")
        print("   - TimeInterval: \(timeInterval)")
        return date
    }
}

// MARK: - Keychain Errors

enum KeychainError: Error {
    case invalidData
    case unhandledError(status: OSStatus)
    
    var localizedDescription: String {
        switch self {
        case .invalidData:
            return "Invalid data format"
        case .unhandledError(let status):
            let errorMessage = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
            return "Keychain error (status: \(status)): \(errorMessage)"
        }
    }
}
