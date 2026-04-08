//
//  DefaultAuthRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

final class DefaultAuthRepository {
    
    private let dataTransferService: DataTransferService
    private let backgroundQueue: DataTransferDispatchQueue
    
    init(
        dataTransferService: DataTransferService,
        backgroundQueue: DataTransferDispatchQueue = DispatchQueue.global(qos: .userInitiated)
    ) {
        self.dataTransferService = dataTransferService
        self.backgroundQueue = backgroundQueue
    }
}

extension DefaultAuthRepository: AuthRepository {
    func signUp(
        fullName: String,
        email: String,
        phone: String,
        password: String,
        completion: @escaping (Result<AuthResult, Error>) -> Void
    ) -> Cancellable? {
        let requestDTO = SignUpRequestDTO(
            fullName: fullName,
            email: email,
            phone: phone,
            password: password
        )
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = APIEndpoints.signUp(with: requestDTO)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                completion(.success(responseDTO.toDomain()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func login(
        phone: String,
        password: String,
        completion: @escaping (Result<AuthResult, Error>) -> Void
    ) -> Cancellable? {
        let requestDTO = LoginRequestDTO(
            phone: phone,
            password: password
        )
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = APIEndpoints.login(with: requestDTO)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                completion(.success(responseDTO.toDomain()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func refreshToken(
        refreshToken: String,
        completion: @escaping (Result<AuthSession, Error>) -> Void
    ) -> Cancellable? {
        let requestDTO = RefreshTokenRequestDTO(refreshToken: refreshToken)
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = APIEndpoints.refreshToken(with: requestDTO)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                completion(.success(responseDTO.toDomain()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func getUserInfo(
        completion: @escaping (Result<User, Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = APIEndpoints.getUserInfo()
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                completion(.success(responseDTO.toDomain()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func resendEmailVerification(
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = APIEndpoints.resendEmailVerification()
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
}
