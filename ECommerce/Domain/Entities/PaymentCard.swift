//
//  PaymentCard.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation

public struct PaymentCard {
    public let id: String
    public let type: String
    public let brand: String
    public let last4: String
    public let expMonth: Int
    public let expYear: Int
    public let isDefault: Bool
    
    public init(
        id: String,
        type: String,
        brand: String,
        last4: String,
        expMonth: Int,
        expYear: Int,
        isDefault: Bool
    ) {
        self.id = id
        self.type = type
        self.brand = brand
        self.last4 = last4
        self.expMonth = expMonth
        self.expYear = expYear
        self.isDefault = isDefault
    }
    
    // MARK: - Computed Properties
    
    public var displayName: String {
        let brandName = brand.capitalized
        return "\(brandName) •••• \(last4)"
    }
    
    public var cardIconName: String {
        // Map brand from backend to icon asset name in Assets.xcassets
        // Stripe API returns brand as lowercase: "visa", "mastercard", "amex", "american_express", etc.
        let brandLowercased = brand.lowercased()
        
        switch brandLowercased {
        case "visa":
            return "visa"
        case "mastercard":
            return "mastercard"
        case "amex", "american_express", "american express":
            return "amex"
        case "jcb":
            return "jcb"
        case "discover":
            return "visa" // Fallback to visa icon if discover icon not available
        case "diners", "diners_club", "diners club":
            return "visa" // Fallback to visa icon if diners icon not available
        case "unionpay", "union_pay":
            return "visa" // Fallback to visa icon if unionpay icon not available
        default:
            return "visa" // Default fallback to visa icon
        }
    }
}
