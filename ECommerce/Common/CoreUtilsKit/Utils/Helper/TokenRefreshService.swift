//
//  TokenRefreshService.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/1/26.
//

import Foundation

/// Service to handle automatic token refresh
/// Singleton to ensure single instance across the app
final class TokenRefreshService {
    
    static let shared = TokenRefreshService()
    
    private var authRepository: AuthRepository?
    private let utilities: Utilities
    
    // Flag to prevent multiple simultaneous refresh requests
    private var isRefreshing = false
    private var refreshQueue: [(Result<AuthSession, Error>) -> Void] = []
    
    private init(utilities: Utilities = Utilities()) {
        self.utilities = utilities
    }
    
    /// Set AuthRepository (should be called once at app startup)
    func setAuthRepository(_ authRepository: AuthRepository) {
        self.authRepository = authRepository
        print("✅ [TokenRefreshService] AuthRepository set for auto-refresh")
    }
    
    /// Check if access token is expired and refresh if needed
    /// - Parameter completion: Callback with refreshed session or error
    /// - Returns: true if refresh was needed and started, false if token is still valid
    func refreshTokenIfNeeded(completion: @escaping (Result<AuthSession, Error>) -> Void) -> Bool {
        print("🔄 [TokenRefreshService] Checking if token refresh is needed...")
        
        // QUAN TRỌNG: Kiểm tra user có đang logged in không
        // Nếu user đã logout, không cần refresh token
        guard utilities.isLoggedIn() else {
            print("⚠️ [TokenRefreshService] User is not logged in, skipping token refresh")
            let error = NSError(
                domain: "TokenRefreshService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "User is not logged in"]
            )
            completion(.failure(error))
            return false
        }
        
        // Check if session is expired
        if !utilities.isSessionExpired() {
            print("✅ [TokenRefreshService] Token is still valid, no refresh needed")
            return false
        }
        
        print("⚠️ [TokenRefreshService] Token is expired, refreshing...")
        
        // Check if already refreshing
        if isRefreshing {
            print("⏳ [TokenRefreshService] Already refreshing, adding to queue")
            refreshQueue.append(completion)
            return true
        }
        
        // Check if AuthRepository is set
        guard let authRepository = authRepository else {
            print("❌ [TokenRefreshService] AuthRepository not set, cannot refresh token")
            let error = NSError(domain: "TokenRefreshService", code: -1, userInfo: [NSLocalizedDescriptionKey: "AuthRepository not initialized"])
            completion(.failure(error))
            return false
        }
        
        // Get refresh token
        guard let refreshToken = utilities.getRefreshToken(), !refreshToken.isEmpty else {
            print("❌ [TokenRefreshService] No refresh token found")
            let error = NSError(domain: "TokenRefreshService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"])
            completion(.failure(error))
            return false
        }
        
        print("🔄 [TokenRefreshService] Starting token refresh...")
        print("   - Refresh Token: \(refreshToken.prefix(20))...")
        
        isRefreshing = true
        refreshQueue.append(completion)
        
        // Call refresh token API
        _ = authRepository.refreshToken(refreshToken: refreshToken) { [weak self] result in
            guard let self = self else { return }
            
            self.isRefreshing = false
            
            switch result {
            case .success(let newSession):
                print("✅ [TokenRefreshService] Token refresh successful")
                print("   - New Access Token: \(newSession.accessToken.prefix(20))...")
                print("   - New Expires At: \(newSession.expiredAt)")
                
                // Save new session to Keychain
                self.utilities.saveSession(
                    accessToken: newSession.accessToken,
                    refreshToken: newSession.refreshToken,
                    expiresAt: newSession.expiredAt
                )
                
                print("✅ [TokenRefreshService] New session saved to Keychain")
                
                // Call all queued completions with success
                let queue = self.refreshQueue
                self.refreshQueue.removeAll()
                
                for completion in queue {
                    completion(.success(newSession))
                }
                
            case .failure(let error):
                print("❌ [TokenRefreshService] Token refresh failed:")
                print("   - Error: \(error.localizedDescription)")
                
                // If refresh token is also expired/invalid, clear session
                if let networkError = error as? NetworkError,
                   case .error(let statusCode, _) = networkError,
                   statusCode == 401 {
                    print("⚠️ [TokenRefreshService] Refresh token expired (401), clearing session")
                    self.utilities.clearSession()
                    self.utilities.saveLogging(false)
                }
                
                // Call all queued completions with error
                let queue = self.refreshQueue
                self.refreshQueue.removeAll()
                
                for completion in queue {
                    completion(.failure(error))
                }
            }
        }
        
        return true
    }
    
    /// Reset TokenRefreshService state (called during logout)
    /// This prevents any pending refresh operations from completing after logout
    func reset() {
        print("🔄 [TokenRefreshService] Resetting service state...")
        
        // Clear refresh queue and notify all pending callbacks with cancellation error
        let queue = refreshQueue
        refreshQueue.removeAll()
        isRefreshing = false
        
        if !queue.isEmpty {
            print("⚠️ [TokenRefreshService] Cancelling \(queue.count) pending refresh callbacks")
            let error = NSError(
                domain: "TokenRefreshService",
                code: NSUserCancelledError,
                userInfo: [NSLocalizedDescriptionKey: "Token refresh cancelled due to logout"]
            )
            
            for completion in queue {
                completion(.failure(error))
            }
        }
        
        print("✅ [TokenRefreshService] Service reset complete")
    }
    
    /// Force refresh token (ignore expiration check)
    /// - Parameter completion: Callback with refreshed session or error
    func forceRefresh(completion: @escaping (Result<AuthSession, Error>) -> Void) {
        print("🔄 [TokenRefreshService] Force refreshing token...")
        
        guard let authRepository = authRepository else {
            print("❌ [TokenRefreshService] AuthRepository not set, cannot refresh token")
            let error = NSError(domain: "TokenRefreshService", code: -1, userInfo: [NSLocalizedDescriptionKey: "AuthRepository not initialized"])
            completion(.failure(error))
            return
        }
        
        guard let refreshToken = utilities.getRefreshToken(), !refreshToken.isEmpty else {
            print("❌ [TokenRefreshService] No refresh token found")
            let error = NSError(domain: "TokenRefreshService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"])
            completion(.failure(error))
            return
        }
        
        _ = authRepository.refreshToken(refreshToken: refreshToken) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let newSession):
                print("✅ [TokenRefreshService] Force refresh successful")
                
                // Save new session
                self.utilities.saveSession(
                    accessToken: newSession.accessToken,
                    refreshToken: newSession.refreshToken,
                    expiresAt: newSession.expiredAt
                )
                
                completion(.success(newSession))
                
            case .failure(let error):
                print("❌ [TokenRefreshService] Force refresh failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}
