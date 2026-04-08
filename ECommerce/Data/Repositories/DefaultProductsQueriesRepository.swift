//
//  DefaultProductsQueriesRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/11/25.
//

import Foundation

final class DefaultProductsQueriesRepository {
    
    private let key = "products.recent.queries"
    private let maxCount = 10
    
    init() {}
}

extension DefaultProductsQueriesRepository: ProductsQueriesRepository {
    
    func fetchRecentsQueries(
        maxCount: Int,
        completion: @escaping (Result<[ProductQuery], Error>) -> Void
    ) {
        guard let data = UserDefaults.standard.data(forKey: key),
              let queries = try? JSONDecoder().decode([String].self, from: data)
        else {
            completion(.success([]))
            return
        }
        
        let productQueries = queries.map { ProductQuery(query: $0) }
        let limitedQueries = Array(productQueries.prefix(maxCount))
        completion(.success(limitedQueries))
    }
    
    func saveRecentQuery(
        query: ProductQuery,
        completion: @escaping (Result<ProductQuery, Error>) -> Void
    ) {
        var queries: [String] = []
        
        if let data = UserDefaults.standard.data(forKey: key),
           let savedQueries = try? JSONDecoder().decode([String].self, from: data) {
            queries = savedQueries
        }
        
        // Remove duplicate (case-insensitive)
        queries.removeAll { $0.lowercased() == query.query.lowercased() }
        
        // Insert at beginning
        queries.insert(query.query, at: 0)
        
        // Limit count
        if queries.count > maxCount {
            queries = Array(queries.prefix(maxCount))
        }
        
        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(queries) {
            UserDefaults.standard.set(data, forKey: key)
        }
        
        completion(.success(query))
    }
}
