//
//  DefaultOrderManageRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation

final class DefaultOrderManageRepository {
    
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

extension DefaultOrderManageRepository: OrderManageRepository {
    
    func fetchOrders(
        completion: @escaping (Result<[OrderManage], Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = OrderManageEndpoints.getOrders()
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { [weak self] result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                let orders = responseDTO.data.map { $0.toDomain() }
                completion(.success(orders))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
}
