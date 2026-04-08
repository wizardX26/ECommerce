//
//  DefaultCategoriesRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 7/1/26.
//

import Foundation

final class DefaultCategoriesRepository {
    
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

extension DefaultCategoriesRepository: CategoriesRepository {
    func fetchCategories(
        cached: @escaping ([Category]) -> Void,
        completion: @escaping (Result<[Category], Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        // Fetch from network
        let endpoint = APIEndpoints.getCategories()
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { [weak self] result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                let categories = responseDTO.toDomain()
                completion(.success(categories))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
}
