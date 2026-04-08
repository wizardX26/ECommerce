//
//  SearchProductsUseCase.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

protocol SearchProductsUseCase {
    func execute(
        query: String,
        completion: @escaping (Result<ProductPage, Error>) -> Void
    ) -> Cancellable?
}

final class DefaultSearchProductsUseCase: SearchProductsUseCase {
    
    private let productsRepository: ProductsRepository
    
    init(productsRepository: ProductsRepository) {
        self.productsRepository = productsRepository
    }
    
    func execute(
        query: String,
        completion: @escaping (Result<ProductPage, Error>) -> Void
    ) -> Cancellable? {
        let productQuery = ProductQuery(query: query)
        return productsRepository.searchProducts(
            query: productQuery,
            page: 0,
            pageSize: 15,
            completion: completion
        )
    }
}
