//
//  PaymentCardDTOs+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation

// MARK: - Create Customer

struct CreateCustomerResponseDTO: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: CustomerDataDTO
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

struct CustomerDataDTO: Decodable {
    let customerId: String
    let ephemeralKey: String? // Optional - có thể có hoặc không
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
        case ephemeralKey = "ephemeral_key"
    }
}

// MARK: - Payment Methods

struct PaymentMethodsResponseDTO: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: [PaymentMethodDTO]
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

struct PaymentMethodDTO: Codable {
    let id: String
    let type: String
    let card: CardDTO?
    let isDefault: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case card
        case isDefault = "is_default"
    }
}

struct CardDTO: Codable {
    let brand: String
    let last4: String
    let expMonth: Int
    let expYear: Int
    
    enum CodingKeys: String, CodingKey {
        case brand
        case last4
        case expMonth = "exp_month"
        case expYear = "exp_year"
    }
}

// MARK: - Attach Payment Method

struct AttachPaymentMethodRequestDTO: Encodable {
    let paymentMethodId: String
    
    enum CodingKeys: String, CodingKey {
        case paymentMethodId = "payment_method_id"
    }
}

struct AttachPaymentMethodResponseDTO: Codable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: PaymentMethodDTO?
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// MARK: - Set Default Payment Method

struct SetDefaultPaymentMethodRequestDTO: Encodable {
    let paymentMethodId: String
    
    enum CodingKeys: String, CodingKey {
        case paymentMethodId = "payment_method_id"
    }
}

struct SetDefaultPaymentMethodResponseDTO: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: DefaultPaymentMethodDataDTO?
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

struct DefaultPaymentMethodDataDTO: Decodable {
    let paymentMethodId: String
    let isDefault: Bool
    
    enum CodingKeys: String, CodingKey {
        case paymentMethodId = "payment_method_id"
        case isDefault = "is_default"
    }
}

// MARK: - Delete Payment Method Response

struct DeletePaymentMethodResponseDTO: Codable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: String? // Usually null for delete

    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

// MARK: - Create Payment Intent

struct CreatePaymentIntentRequestDTO: Encodable {
    let orderId: Int
    let amount: Int
    let paymentMethodId: String?
    
    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case amount
        case paymentMethodId = "payment_method_id"
    }
}

struct CreatePaymentIntentResponseDTO: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: PaymentIntentDataDTO
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

struct PaymentIntentDataDTO: Decodable {
    let clientSecret: String
    let paymentIntentId: String
    let customerId: String? // Optional - có thể có hoặc không
    let ephemeralKey: String? // Optional - có thể có hoặc không
    
    enum CodingKeys: String, CodingKey {
        case clientSecret = "client_secret"
        case paymentIntentId = "payment_intent_id"
        case customerId = "customer_id"
        case ephemeralKey = "ephemeral_key"
    }
}

// MARK: - Confirm Payment

struct ConfirmPaymentRequestDTO: Encodable {
    let paymentIntentId: String
    
    enum CodingKeys: String, CodingKey {
        case paymentIntentId = "payment_intent_id"
    }
}

struct ConfirmPaymentResponseDTO: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: ConfirmPaymentDataDTO
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}

struct ConfirmPaymentDataDTO: Decodable {
    let status: String
    let paymentIntentId: String
    let orderId: Int
    
    enum CodingKeys: String, CodingKey {
        case status
        case paymentIntentId = "payment_intent_id"
        case orderId = "order_id"
    }
}

// MARK: - Mappings to Domain

extension PaymentMethodDTO {
    func toDomain() -> PaymentCard {
        return PaymentCard(
            id: id,
            type: type,
            brand: card?.brand ?? "",
            last4: card?.last4 ?? "",
            expMonth: card?.expMonth ?? 0,
            expYear: card?.expYear ?? 0,
            isDefault: isDefault
        )
    }
}
