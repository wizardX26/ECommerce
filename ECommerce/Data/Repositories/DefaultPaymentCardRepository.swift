//
//  DefaultPaymentCardRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation

final class DefaultPaymentCardRepository {
    
    private let dataTransferService: DataTransferService
    private let backgroundQueue: DataTransferDispatchQueue
    
    init(
        dataTransferService: DataTransferService,
        backgroundQueue: DataTransferDispatchQueue = DispatchQueue.global(qos: .userInitiated)
    ) {
        self.dataTransferService = dataTransferService
        self.backgroundQueue = backgroundQueue
    }
    
    // MARK: - Helper Methods
    
    /// Extract backend message from error response body
    private func extractBackendMessage(from error: Error) -> String? {
        // Check if it's a DataTransferError with networkFailure
        if case .networkFailure(let networkError) = error as? DataTransferError,
           case .error(_, let data) = networkError {
            return extractMessageFromErrorData(data)
        }
        
        // Check if it's directly a NetworkError
        if case .error(_, let data) = error as? NetworkError {
            return extractMessageFromErrorData(data)
        }
        
        return nil
    }
    
    /// Extract message from error response data (tries to decode as DTO first, then falls back to JSON parsing)
    private func extractMessageFromErrorData(_ data: Data?) -> String? {
        guard let data = data else { return nil }
        
        // Try to decode as AttachPaymentMethodResponseDTO or DeletePaymentMethodResponseDTO
        if let attachResponse = try? JSONDecoder().decode(AttachPaymentMethodResponseDTO.self, from: data) {
            #if DEBUG
            print("📦 [PaymentCard] Decoded error response as AttachPaymentMethodResponseDTO: statusCode=\(attachResponse.statusCode) success=\(attachResponse.success) message=\(attachResponse.message)")
            #endif
            return attachResponse.message
        }
        
        if let deleteResponse = try? JSONDecoder().decode(DeletePaymentMethodResponseDTO.self, from: data) {
            #if DEBUG
            print("📦 [PaymentCard] Decoded error response as DeletePaymentMethodResponseDTO: statusCode=\(deleteResponse.statusCode) success=\(deleteResponse.success) message=\(deleteResponse.message)")
            #endif
            return deleteResponse.message
        }
        
        // Fallback to JSON parsing
        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            if let message = jsonObject["message"] as? String, !message.isEmpty {
                #if DEBUG
                print("📦 [PaymentCard] Extracted message from JSON: \(message)")
                #endif
                return message
            }
        }
        
        return nil
    }
}

extension DefaultPaymentCardRepository: PaymentCardRepository {
    
    func createCustomer(completion: @escaping (Result<String, Error>) -> Void) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = APIEndpoints.createCustomer()
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                // Trả về customerId và ephemeralKey nếu có
                completion(.success(responseDTO.data.customerId))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func getPaymentMethods(completion: @escaping (Result<[PaymentCard], Error>) -> Void) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = APIEndpoints.getPaymentMethods()
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                let paymentCards = responseDTO.data.map { $0.toDomain() }
                completion(.success(paymentCards))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func attachPaymentMethod(paymentMethodId: String, completion: @escaping (Result<(PaymentCard, String), Error>) -> Void) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let requestDTO = AttachPaymentMethodRequestDTO(paymentMethodId: paymentMethodId)
        let endpoint = APIEndpoints.attachPaymentMethod(with: requestDTO)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                #if DEBUG
                print("✅ [PaymentCard][attach-payment-method] statusCode=\(responseDTO.statusCode) success=\(responseDTO.success) message=\(responseDTO.message)")
                if let jsonData = try? JSONEncoder().encode(responseDTO),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("📦 [PaymentCard][attach-payment-method] Full Response: \(jsonString)")
                }
                #endif
                
                // Check if backend returned success=false (even with HTTP 200)
                if !responseDTO.success {
                    completion(.failure(NSError(
                        domain: "PaymentCardRepository",
                        code: responseDTO.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: responseDTO.message]
                    )))
                    return
                }
                
                if let paymentMethod = responseDTO.data {
                    completion(.success((paymentMethod.toDomain(), responseDTO.message)))
                } else {
                    completion(.failure(NSError(
                        domain: "PaymentCardRepository",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: responseDTO.message]
                    )))
                }
            case .failure(let error):
                #if DEBUG
                print("❌ [PaymentCard][attach-payment-method] error=\(error)")
                #endif
                
                // Try to extract message from error response body
                let backendMessage = self.extractBackendMessage(from: error)
                if let message = backendMessage {
                    completion(.failure(NSError(
                        domain: "PaymentCardRepository",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: message]
                    )))
                } else {
                    completion(.failure(error))
                }
            }
        }
        return task
    }
    
    func deletePaymentMethod(id: String, completion: @escaping (Result<String, Error>) -> Void) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = APIEndpoints.deletePaymentMethod(id: id)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                #if DEBUG
                print("✅ [PaymentCard][delete-payment-method] statusCode=\(responseDTO.statusCode) success=\(responseDTO.success) message=\(responseDTO.message)")
                if let jsonData = try? JSONEncoder().encode(responseDTO),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("📦 [PaymentCard][delete-payment-method] Full Response: \(jsonString)")
                }
                #endif
                
                // Check if backend returned success=false (even with HTTP 200)
                if !responseDTO.success {
                    completion(.failure(NSError(
                        domain: "PaymentCardRepository",
                        code: responseDTO.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: responseDTO.message]
                    )))
                    return
                }
                
                completion(.success(responseDTO.message))
            case .failure(let error):
                #if DEBUG
                print("❌ [PaymentCard][delete-payment-method] error=\(error)")
                #endif
                
                // Try to extract message from error response body
                let backendMessage = self.extractBackendMessage(from: error)
                if let message = backendMessage {
                    completion(.failure(NSError(
                        domain: "PaymentCardRepository",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: message]
                    )))
                } else {
                    completion(.failure(error))
                }
            }
        }
        return task
    }
    
    func setDefaultPaymentMethod(paymentMethodId: String, completion: @escaping (Result<Void, Error>) -> Void) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let requestDTO = SetDefaultPaymentMethodRequestDTO(paymentMethodId: paymentMethodId)
        let endpoint = APIEndpoints.setDefaultPaymentMethod(with: requestDTO)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func createPaymentIntent(orderId: Int, amount: Int, paymentMethodId: String?, completion: @escaping (Result<PaymentIntent, Error>) -> Void) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        print("📤 [DefaultPaymentCardRepository] Creating payment intent request")
        print("   - orderId: \(orderId)")
        print("   - amount (Int): \(amount)")
        print("   - paymentMethodId: \(paymentMethodId ?? "nil")")
        print("   - ⚠️ VND: amount trực tiếp, KHÔNG nhân 100")
        
        let requestDTO = CreatePaymentIntentRequestDTO(orderId: orderId, amount: amount, paymentMethodId: paymentMethodId)
        let endpoint = APIEndpoints.createPaymentIntent(with: requestDTO)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                let paymentIntent = PaymentIntent(
                    clientSecret: responseDTO.data.clientSecret,
                    paymentIntentId: responseDTO.data.paymentIntentId,
                    customerId: responseDTO.data.customerId,
                    ephemeralKey: responseDTO.data.ephemeralKey
                )
                completion(.success(paymentIntent))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func confirmPayment(paymentIntentId: String, completion: @escaping (Result<PaymentConfirmation, Error>) -> Void) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let requestDTO = ConfirmPaymentRequestDTO(paymentIntentId: paymentIntentId)
        let endpoint = APIEndpoints.confirmPayment(with: requestDTO)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                let confirmation = PaymentConfirmation(
                    status: responseDTO.data.status,
                    paymentIntentId: responseDTO.data.paymentIntentId,
                    orderId: responseDTO.data.orderId
                )
                completion(.success(confirmation))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
}
