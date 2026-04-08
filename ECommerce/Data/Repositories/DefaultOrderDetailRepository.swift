//
//  DefaultOrderDetailRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation

final class DefaultOrderDetailRepository {
    
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

extension DefaultOrderDetailRepository: OrderDetailRepository {
    
    func fetchOrderDetail(
        orderId: Int,
        completion: @escaping (Result<OrderDetail, Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = OrderDetailEndpoints.getOrderDetail(orderId: orderId)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { [weak self] result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                let orderDetail = responseDTO.data.toDomain()
                completion(.success(orderDetail))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func cancelOrder(
        orderId: Int,
        completion: @escaping (Result<String, Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = APIEndpoints.cancelOrder(orderId: orderId)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                completion(.success(responseDTO.message))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
}
