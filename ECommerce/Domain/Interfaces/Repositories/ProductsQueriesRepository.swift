//
//  ProductsQueriesRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/11/25.
//

import Foundation

protocol ProductsQueriesRepository {
    func fetchRecentsQueries(
        maxCount: Int,
        completion: @escaping (Result<[ProductQuery], Error>) -> Void
    )
    func saveRecentQuery(
        query: ProductQuery,
        completion: @escaping (Result<ProductQuery, Error>) -> Void
    )
}
