//
//  PaymentCardEndpoints.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation

enum PaymentCardEndpoints {
    
    // MARK: - Create Customer
    
    static func createCustomer() -> Endpoint<CreateCustomerResponseDTO> {
        return Endpoint(
            path: "api/v1/stripe/create-customer",
            method: .post
        )
    }
    
    // MARK: - Get Payment Methods
    
    static func getPaymentMethods() -> Endpoint<PaymentMethodsResponseDTO> {
        return Endpoint(
            path: "api/v1/stripe/payment-methods",
            method: .get
        )
    }
    
    // MARK: - Attach Payment Method
    
    static func attachPaymentMethod(with requestDTO: AttachPaymentMethodRequestDTO) -> Endpoint<AttachPaymentMethodResponseDTO> {
        return Endpoint(
            path: "api/v1/stripe/attach-payment-method",
            method: .post,
            bodyParametersEncodable: requestDTO
        )
    }
    
    // MARK: - Delete Payment Method
    
    static func deletePaymentMethod(id: String) -> Endpoint<DeletePaymentMethodResponseDTO> {
        return Endpoint(
            path: "api/v1/stripe/payment-methods/\(id)",
            method: .delete
        )
    }
    
    // MARK: - Set Default Payment Method
    
    static func setDefaultPaymentMethod(with requestDTO: SetDefaultPaymentMethodRequestDTO) -> Endpoint<SetDefaultPaymentMethodResponseDTO> {
        return Endpoint(
            path: "api/v1/stripe/set-default-payment-method",
            method: .post,
            bodyParametersEncodable: requestDTO
        )
    }
    
    // MARK: - Create Payment Intent
    
    static func createPaymentIntent(with requestDTO: CreatePaymentIntentRequestDTO) -> Endpoint<CreatePaymentIntentResponseDTO> {
        return Endpoint(
            path: "api/v1/stripe/create-payment-intent",
            method: .post,
            bodyParametersEncodable: requestDTO
        )
    }
    
    // MARK: - Confirm Payment
    
    static func confirmPayment(with requestDTO: ConfirmPaymentRequestDTO) -> Endpoint<ConfirmPaymentResponseDTO> {
        return Endpoint(
            path: "api/v1/stripe/confirm-payment",
            method: .post,
            bodyParametersEncodable: requestDTO
        )
    }
}
