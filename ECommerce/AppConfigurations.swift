import Foundation

final class AppConfiguration {
    lazy var apiKey: String = {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "ApiKey") as? String else {
            fatalError("ApiKey must not be empty in plist")
        }
        return apiKey
    }()
    
    lazy var apiBaseURL: String = {
        guard let apiBaseURL = Bundle.main.object(forInfoDictionaryKey: "ApiBaseURL") as? String else {
            fatalError("ApiBaseURL must not be empty in plist")
        }
        // Log để debug trên thiết bị thật
        print("🔧 [AppConfig] API Base URL: \(apiBaseURL)")
        return apiBaseURL
    }()
    
    lazy var stripePulishableKey: String = {
        guard let stripePulishableKey = Bundle.main.object(forInfoDictionaryKey: "StripePulishableKey") as? String else {
            fatalError("StripePulishableKey must not be empty in plist")
        }
        return stripePulishableKey
    }()
}
