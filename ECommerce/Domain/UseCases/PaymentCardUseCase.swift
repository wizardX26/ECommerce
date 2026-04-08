//
//  PaymentCardUseCase.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation

public protocol PaymentCardUseCase {
    func createCustomer(completion: @escaping (Result<String, Error>) -> Void) -> Cancellable?
    func getPaymentMethods(completion: @escaping (Result<[PaymentCard], Error>) -> Void) -> Cancellable?
    func attachPaymentMethod(paymentMethodId: String, completion: @escaping (Result<(PaymentCard, String), Error>) -> Void) -> Cancellable?
    func deletePaymentMethod(id: String, completion: @escaping (Result<String, Error>) -> Void) -> Cancellable?
    func setDefaultPaymentMethod(paymentMethodId: String, completion: @escaping (Result<Void, Error>) -> Void) -> Cancellable?
    func createPaymentIntent(orderId: Int, amount: Int, paymentMethodId: String?, completion: @escaping (Result<PaymentIntent, Error>) -> Void) -> Cancellable?
    func confirmPayment(paymentIntentId: String, completion: @escaping (Result<PaymentConfirmation, Error>) -> Void) -> Cancellable?
}

final class DefaultPaymentCardUseCase: PaymentCardUseCase {
    
    private let paymentCardRepository: PaymentCardRepository
    
    init(paymentCardRepository: PaymentCardRepository) {
        self.paymentCardRepository = paymentCardRepository
    }
    
    func createCustomer(completion: @escaping (Result<String, Error>) -> Void) -> Cancellable? {
        return paymentCardRepository.createCustomer(completion: completion)
    }
    
    func getPaymentMethods(completion: @escaping (Result<[PaymentCard], Error>) -> Void) -> Cancellable? {
        return paymentCardRepository.getPaymentMethods(completion: completion)
    }
    
    func attachPaymentMethod(paymentMethodId: String, completion: @escaping (Result<(PaymentCard, String), Error>) -> Void) -> Cancellable? {
        return paymentCardRepository.attachPaymentMethod(paymentMethodId: paymentMethodId, completion: completion)
    }
    
    func deletePaymentMethod(id: String, completion: @escaping (Result<String, Error>) -> Void) -> Cancellable? {
        return paymentCardRepository.deletePaymentMethod(id: id, completion: completion)
    }
    
    func setDefaultPaymentMethod(paymentMethodId: String, completion: @escaping (Result<Void, Error>) -> Void) -> Cancellable? {
        return paymentCardRepository.setDefaultPaymentMethod(paymentMethodId: paymentMethodId, completion: completion)
    }
    
    func createPaymentIntent(orderId: Int, amount: Int, paymentMethodId: String?, completion: @escaping (Result<PaymentIntent, Error>) -> Void) -> Cancellable? {
        return paymentCardRepository.createPaymentIntent(orderId: orderId, amount: amount, paymentMethodId: paymentMethodId, completion: completion)
    }
    
    func confirmPayment(paymentIntentId: String, completion: @escaping (Result<PaymentConfirmation, Error>) -> Void) -> Cancellable? {
        return paymentCardRepository.confirmPayment(paymentIntentId: paymentIntentId, completion: completion)
    }
}
