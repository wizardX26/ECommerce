//
//  DefaultLocationListRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

final class DefaultLocationListRepository {
    
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

extension DefaultLocationListRepository: LocationListRepository {
    func getAddresses(
        completion: @escaping (Result<[Address], Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = APIEndpoints.getAddresses()
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                let addresses = responseDTO.addresses.map { $0.toDomain() }
                completion(.success(addresses))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
}
