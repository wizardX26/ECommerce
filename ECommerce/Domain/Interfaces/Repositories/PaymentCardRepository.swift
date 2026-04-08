//
//  PaymentCardRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation

protocol PaymentCardRepository {
    func createCustomer(completion: @escaping (Result<String, Error>) -> Void) -> Cancellable?
    func getPaymentMethods(completion: @escaping (Result<[PaymentCard], Error>) -> Void) -> Cancellable?
    /// - Returns: (savedCard, backendMessage)
    func attachPaymentMethod(paymentMethodId: String, completion: @escaping (Result<(PaymentCard, String), Error>) -> Void) -> Cancellable?
    /// - Returns: backendMessage
    func deletePaymentMethod(id: String, completion: @escaping (Result<String, Error>) -> Void) -> Cancellable?
    func setDefaultPaymentMethod(paymentMethodId: String, completion: @escaping (Result<Void, Error>) -> Void) -> Cancellable?
    func createPaymentIntent(orderId: Int, amount: Int, paymentMethodId: String?, completion: @escaping (Result<PaymentIntent, Error>) -> Void) -> Cancellable?
    func confirmPayment(paymentIntentId: String, completion: @escaping (Result<PaymentConfirmation, Error>) -> Void) -> Cancellable?
}

// MARK: - Supporting Types

public struct PaymentIntent {
    public let clientSecret: String
    public let paymentIntentId: String
    public let customerId: String?
    public let ephemeralKey: String?
    
    public init(clientSecret: String, paymentIntentId: String, customerId: String? = nil, ephemeralKey: String? = nil) {
        self.clientSecret = clientSecret
        self.paymentIntentId = paymentIntentId
        self.customerId = customerId
        self.ephemeralKey = ephemeralKey
    }
}

public struct PaymentConfirmation {
    public let status: String
    public let paymentIntentId: String
    public let orderId: Int
    
    public init(status: String, paymentIntentId: String, orderId: Int) {
        self.status = status
        self.paymentIntentId = paymentIntentId
        self.orderId = orderId
    }
}
