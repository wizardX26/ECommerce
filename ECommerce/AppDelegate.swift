//
//  AppDelegate.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/11/25.
//

import UIKit
import Stripe
import UserNotifications


@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    let appConfiguration = AppConfiguration()
    var appDIContainer: AppDIContainer {
        return AppDIContainer.shared
    }
    var appFlowCoordinator: AppFlowCoordinator?
    var window: UIWindow?
    var splashCoordinatingController: SplashCoordinatingController? // Keep strong reference
    
    private let notificationCenter = UNUserNotificationCenter.current()

    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        StripeAPI.defaultPublishableKey = self.appConfiguration.stripePulishableKey
        AppAppearance.setupAppearance()
        
        // Setup TokenRefreshService with AuthRepository for auto-refresh
        let authSceneDIContainer = self.appDIContainer.makeAuthSceneDIContainer()
        let authRepository = authSceneDIContainer.makeAuthRepository()
        TokenRefreshService.shared.setAuthRepository(authRepository)
        print("✅ [AppDelegate] TokenRefreshService configured for auto-refresh")
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Set SplashViewController as entry point
        let onboardSceneDIContainer = self.appDIContainer.makeOnboardSceneDIContainer()
        self.splashCoordinatingController = onboardSceneDIContainer.makeSplashCoordinatingController(
            navigationController: nil,
            window: window
        )
        self.splashCoordinatingController?.start()
        // Note: window.makeKeyAndVisible() is called inside start() method

        // Reload app when user changes language (Login/Sign-up right bar: EN/VI)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadAppForLanguageChange),
            name: Foundation.Notification.Name.LanguageChangeNotification,
            object: nil
        )

        // Setup notification delegate (but don't request permission yet)
        // Permission will be requested when you call AppDelegate.requestPushNotificationPermission()
        self.setupNotificationDelegate()
        
        // Trigger local network permission request by making a test connection
        // This helps iOS recognize that the app needs local network access
        self.triggerLocalNetworkPermission()
        
        // Try to send device token if user is already logged in (app relaunch)
        // Delay lâu hơn để đảm bảo không có race condition với logout/login flow
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            AppDelegate.sendDeviceTokenToServerIfLoggedIn()
        }
    
        return true
    }
    
    /// Triggers local network permission request by attempting a connection to local server
    /// This helps iOS recognize the app needs local network access and show it in Settings
    private func triggerLocalNetworkPermission() {
        guard let baseURL = URL(string: appConfiguration.apiBaseURL) else {
            print("⚠️ [AppDelegate] Invalid base URL, cannot trigger local network permission")
            return
        }
        
        // Create a simple test request to trigger local network permission
        var request = URLRequest(url: baseURL)
        request.httpMethod = "HEAD" // HEAD request is lightweight, just checks if server is reachable
        request.timeoutInterval = 2.0 // Short timeout, we don't care about the response
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                let nsError = error as NSError
                if nsError.code == NSURLErrorNotConnectedToInternet || 
                   nsError.domain == NSURLErrorDomain {
                    print("🔔 [AppDelegate] Local network permission may be needed. Check Settings > Privacy & Security > Local Network")
                }
            } else if let httpResponse = response as? HTTPURLResponse {
                print("✅ [AppDelegate] Local network connection successful: \(httpResponse.statusCode)")
            }
        }
        
        task.resume()
        print("🔧 [AppDelegate] Triggered local network permission check to: \(baseURL.absoluteString)")
    }

//    func applicationDidEnterBackground(_ application: UIApplication) {
//        CoreDataStorage.shared.saveContext()
//    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert the device token Data to a String
        let tokenParts = deviceToken.map { data in
            String(format: "%02.2hhx", data)
        }
        let newToken = tokenParts.joined()
        
        // Print the token to the console (for debugging)
        print("📱 [AppDelegate] Device Token received: \(newToken)")
        
        // Save device token to UserDefaults
        UserDefaults.standard.set(newToken, forKey: Constants.UserDefaultsKey.deviceToken)
        print("💾 [AppDelegate] Device token saved to UserDefaults")
        
        // Try to send token if user is already logged in
        AppDelegate.sendDeviceTokenToServerIfLoggedIn()
    }
    
    // Static method to send device token - can be called from anywhere after login
    static func sendDeviceTokenToServerIfLoggedIn() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        // Get saved device token
        guard let deviceToken = UserDefaults.standard.string(forKey: Constants.UserDefaultsKey.deviceToken),
              !deviceToken.isEmpty else {
            print("⚠️ [AppDelegate] No device token saved, skipping registration")
            return
        }
        
        // Get access token if user is logged in
        let utilities = Utilities()
        
        // Kiểm tra user có đang logged in không
        guard utilities.isLoggedIn() else {
            print("⚠️ [AppDelegate] User is not logged in, skipping device token registration")
            return
        }
        
        // Kiểm tra access token tồn tại và không rỗng
        guard let accessToken = utilities.getAccessToken(), !accessToken.isEmpty else {
            print("⚠️ [AppDelegate] No access token, device token will be sent after login")
            return
        }
        
        // Kiểm tra session không expired (tránh gửi với token đã hết hạn)
        if utilities.isSessionExpired() {
            print("⚠️ [AppDelegate] Session is expired, skipping device token registration")
            return
        }
        
        // Send token to server
        appDelegate.sendDeviceTokenToServer(token: deviceToken)
    }

    // Send device token to backend server
    private func sendDeviceTokenToServer(token: String) {
        // Build API URL
        guard let baseURL = URL(string: appConfiguration.apiBaseURL),
              let registerURL = URL(string: "\(baseURL.absoluteString)/api/v1/device/register") else {
            print("❌ [AppDelegate] Invalid API base URL")
            return
        }
        
        // Get access token
        let utilities = Utilities()
        guard let accessToken = utilities.getAccessToken(), !accessToken.isEmpty else {
            print("❌ [AppDelegate] No access token available")
            return
        }
        
        // Get device info
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        // Create request body
        let body: [String: Any] = [
            "device_token": token,
            "platform": "ios",
            "device_id": deviceID,
            "app_version": appVersion
        ]
        
        // Print JSON body
        if let jsonData = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 [AppDelegate] POST Request Body (JSON):")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print(jsonString)
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
        
        // Create request
        var request = URLRequest(url: registerURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode body to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("❌ [AppDelegate] Failed to encode request body")
            return
        }
        request.httpBody = jsonData
        
        // Print request details
        print("📡 [AppDelegate] Request Details:")
        print("   URL: \(registerURL.absoluteString)")
        print("   Method: POST")
        print("   Headers:")
        print("     Authorization: Bearer \(accessToken.prefix(20))...")
        print("     Content-Type: application/json")
        print("   Body Size: \(jsonData.count) bytes")
        
        // Send request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [AppDelegate] Failed to send device token: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    print("✅ [AppDelegate] Device token registered successfully")
                    
                    // Print response body if available
                    if let data = data,
                       let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                       let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("📥 [AppDelegate] Response Body:")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        print(jsonString)
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    }
                } else {
                    print("⚠️ [AppDelegate] Device token registration failed with status: \(httpResponse.statusCode)")
                    
                    // Print error response if available
                    if let data = data,
                       let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
                       let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("📥 [AppDelegate] Error Response Body:")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        print(jsonString)
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    }
                }
            }
        }
        
        task.resume()
        print("📤 [AppDelegate] Sending device token to server: \(token.prefix(20))...")
    }

    @objc private func reloadAppForLanguageChange() {
        print("🌐 [AppDelegate] Language change detected, reloading app...")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("🌐 [AppDelegate] Current language: \(Localize.currentLanguage())")
            // Reload app by restarting from splash screen
            // This will recreate all view controllers with new language
            self.splashCoordinatingController?.start()
            print("🌐 [AppDelegate] App reloaded with new language")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    /// Setup notification delegate (called once at app launch)
    private func setupNotificationDelegate() {
        notificationCenter.delegate = self
        print("🔔 [AppDelegate] Notification delegate setup completed")
    }
    
    /// Request push notification permission - Call this method when you want to show the permission popup
    /// Can be called from anywhere in your app (e.g., after login, on a specific screen, etc.)
    static func requestPushNotificationPermission() {
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Check current authorization status first
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                // User hasn't been asked yet - show permission popup
                print("🔔 [AppDelegate] Requesting push notification permission...")
                notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ [AppDelegate] Error requesting notification permission: \(error.localizedDescription)")
                            return
                        }
                        
                        if granted {
                            print("✅ [AppDelegate] Push notification permission granted")
                            // Register for remote notifications to get device token
                            UIApplication.shared.registerForRemoteNotifications()
                        } else {
                            print("⚠️ [AppDelegate] Push notification permission denied")
                        }
                    }
                }
            case .authorized:
                // Already authorized - just register for remote notifications
                print("✅ [AppDelegate] Push notification already authorized, registering for remote notifications...")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .denied:
                // User denied permission - can't request again, need to go to Settings
                print("⚠️ [AppDelegate] Push notification permission denied. User needs to enable in Settings.")
            case .provisional:
                // Provisional authorization (for quiet notifications)
                print("ℹ️ [AppDelegate] Push notification has provisional authorization")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .ephemeral:
                // Ephemeral authorization (for App Clips)
                print("ℹ️ [AppDelegate] Push notification has ephemeral authorization")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            @unknown default:
                print("⚠️ [AppDelegate] Unknown notification authorization status")
            }
        }
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [AppDelegate] Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    /// Called when notification arrives while app is in FOREGROUND
    /// This allows you to show the notification even when app is active
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        
        print("📲 [AppDelegate] Notification received while app is in FOREGROUND")
        print("   Title: \(notification.request.content.title)")
        print("   Body: \(notification.request.content.body)")
        print("   UserInfo: \(userInfo)")
        
        // Notify that a new push notification has arrived
        // This will trigger refresh in NotificationViewController if it's currently visible
        // Post on main thread to ensure UI updates happen correctly
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .newPushNotificationReceived, object: nil)
        }
        
        // Show notification as banner, sound, and badge even when app is active
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            // Fallback on earlier versions
        }
    }
    
    /// Called when user TAPS on a notification
    /// This is called when:
    /// 1. App is in FOREGROUND and user taps notification
    /// 2. App is in BACKGROUND and user taps notification
    /// 3. App is KILLED and user taps notification (app will be launched)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Determine app state when notification was tapped
        let appState = UIApplication.shared.applicationState
        let stateDescription: String
        switch appState {
        case .active:
            stateDescription = "app was active (foreground)"
        case .inactive:
            stateDescription = "app was inactive (transitioning)"
        case .background:
            stateDescription = "app was in background"
        @unknown default:
            stateDescription = "app was killed/launched"
        }
        
        print("📲 [AppDelegate] User tapped notification (\(stateDescription))")
        print("   Title: \(response.notification.request.content.title)")
        print("   Body: \(response.notification.request.content.body)")
        print("   UserInfo: \(userInfo)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // TODO: Navigate to specific screen based on notification data
        // Example: Navigate to order detail, product detail, etc.
        handleNotificationTap(userInfo: userInfo)
        
        completionHandler()
    }
    
    /// Handle notification tap - navigate to appropriate screen
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Extract notification data
        // Example: if notification contains order_id, navigate to order detail
        // Example: if notification contains product_id, navigate to product detail
        
        // Get notification type or action from userInfo
        if let notificationType = userInfo["type"] as? String {
            print("🔔 [AppDelegate] Notification type: \(notificationType)")
            
            switch notificationType {
            case "order":
                if let orderId = userInfo["order_id"] as? Int {
                    print("   → Navigate to Order Detail: \(orderId)")
                    // TODO: Navigate to order detail screen
                    // navigateToOrderDetail(orderId: orderId)
                }
            case "product":
                if let productId = userInfo["product_id"] as? Int {
                    print("   → Navigate to Product Detail: \(productId)")
                    // TODO: Navigate to product detail screen
                    // navigateToProductDetail(productId: productId)
                }
            default:
                print("   → Unknown notification type, no navigation")
            }
        } else {
            print("   → No notification type found, default handling")
        }
    }
}
