//
//  DefaultProductsRepository.swift
//  ExampleMVVM
//
//  Created by wizard.os25 on 14/11/25.
//

import Foundation

final class DefaultProductsRepository {

    private let dataTransferService: DataTransferService
    private let cacheStorage: ProductsResponseStorage?
    private let backgroundQueue: DataTransferDispatchQueue

    init(
        dataTransferService: DataTransferService,
        cacheStorage: ProductsResponseStorage? = nil,
        backgroundQueue: DataTransferDispatchQueue = DispatchQueue.global(qos: .userInitiated)
    ) {
        self.dataTransferService = dataTransferService
        self.cacheStorage = cacheStorage
        self.backgroundQueue = backgroundQueue
    }
}

extension DefaultProductsRepository: ProductsRepository {
    func fetchProductsList(
        query: ProductQuery,
        page: Int,
        pageSize: Int,
        cached: @escaping (ProductPage) -> Void,
        completion: @escaping (Result<ProductPage, Error>) -> Void
    ) -> Cancellable? {
        let requestDTO = ProductsRequestDTO(query: query.query, page: page, pageSize: pageSize)
        let task = RepositoryTask()
        
        print("🌐 [ProductsRepository] Starting fetch - Query: '\(query.query)', Page: \(page), PageSize: \(pageSize)")
        
        guard !task.isCancelled else {
            print("⚠️ [ProductsRepository] Task cancelled before start")
            return nil
        }
        
        // 1. Try cache first (non-blocking, async)
        if let cacheStorage = cacheStorage {
            print("💾 [ProductsRepository] Checking cache...")
            cacheStorage.getResponse(for: requestDTO) { [weak self] result in
                guard !task.isCancelled else { return }
                
                if case .success(let responseDTO?) = result {
                    // Cache hit: Convert to domain and call cached callback
                    print("✅ [ProductsRepository] Cache hit - Found \(responseDTO.contents.count) items in cache")
                    let cachedPage = responseDTO.toDomain()
                    self?.backgroundQueue.asyncExecute {
                        cached(cachedPage)
                    }
                } else {
                    print("💾 [ProductsRepository] Cache miss - No cached data found")
                }
                // Cache miss: Continue to network (no action needed)
            }
        } else {
            print("💾 [ProductsRepository] No cache storage available")
        }
        
        // 2. Fetch from network (always, regardless of cache)
        let endpoint = APIEndpoints.getProducts(with: requestDTO)
        print("🌐 [ProductsRepository] Fetching from network - Endpoint: \(endpoint.path)")
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { [weak self] result in
            guard !task.isCancelled else {
                print("⚠️ [ProductsRepository] Task cancelled during network request")
                return
            }
            
            switch result {
            case .success(let responseDTO):
                print("✅ [ProductsRepository] Network success - Received \(responseDTO.contents.count) items, Total: \(responseDTO.totalElements), HasMore: \(responseDTO.hasMore)")
                // Save to cache (async, non-blocking)
                self?.cacheStorage?.save(response: responseDTO, for: requestDTO)
                print("💾 [ProductsRepository] Saved to cache")
                // Call completion with fresh data
                completion(.success(responseDTO.toDomain()))
            case .failure(let error):
                print("❌ [ProductsRepository] Network error - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        return task
    }
    
    func searchProducts(
        query: ProductQuery,
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<ProductPage, Error>) -> Void
    ) -> Cancellable? {
        let task = RepositoryTask()
        
        print("🔍 [ProductsRepository] Starting search - Query: '\(query.query)', Page: \(page), PageSize: \(pageSize)")
        
        guard !task.isCancelled else {
            print("⚠️ [ProductsRepository] Search task cancelled before start")
            return nil
        }
        
        // Fetch from network (search doesn't use cache)
        let endpoint = APIEndpoints.searchProducts(query: query.query)
        print("🌐 [ProductsRepository] Searching from network - Endpoint: \(endpoint.path)")
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else {
                print("⚠️ [ProductsRepository] Search task cancelled during network request")
                return
            }
            
            switch result {
            case .success(let responseDTO):
                print("✅ [ProductsRepository] Search success - Received \(responseDTO.contents.count) items, Total: \(responseDTO.totalElements), HasMore: \(responseDTO.hasMore)")
                completion(.success(responseDTO.toDomain()))
            case .failure(let error):
                print("❌ [ProductsRepository] Search error - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        return task
    }
}
