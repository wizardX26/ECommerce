//
//  DefaultProfileRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

final class DefaultProfileRepository {
    
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

extension DefaultProfileRepository: ProfileRepository {
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
    
    func updateProfile(
        fName: String?,
        email: String?,
        phone: String?,
        completion: @escaping (Result<User, Error>) -> Void
    ) -> Cancellable? {
        let requestDTO = UpdateProfileRequestDTO(
            fullName: fName,
            email: email,
            phone: phone
        )
        
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = APIEndpoints.updateProfile(with: requestDTO)
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
    
    func changePassword(
        currentPassword: String,
        newPassword: String,
        newPasswordConfirmation: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable? {
        let requestDTO = ChangePasswordRequestDTO(
            currentPassword: currentPassword,
            newPassword: newPassword,
            newPasswordConfirmation: newPasswordConfirmation
        )
        
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = APIEndpoints.changePassword(with: requestDTO)
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
