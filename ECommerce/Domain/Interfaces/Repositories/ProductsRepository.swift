//
//  ProductsRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/11/25.
//

import Foundation

protocol ProductsRepository {
    @discardableResult
    func fetchProductsList(
        query: ProductQuery,
        page: Int,
        pageSize: Int,
        cached: @escaping (ProductPage) -> Void,
        completion: @escaping (Result<ProductPage, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func searchProducts(
        query: ProductQuery,
        page: Int,
        pageSize: Int,
        completion: @escaping (Result<ProductPage, Error>) -> Void
    ) -> Cancellable?
}
