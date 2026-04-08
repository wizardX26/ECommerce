//
//  FetchRecentProductQueriesUseCase.swift
//  ExampleMVVM
//
//  Created by wizard.os25 on 14/11/25.
//

import Foundation

final class FetchRecentProductQueriesUseCase: UseCase {

    struct RequestValue {
        let maxCount: Int
    }
    typealias ResultValue = (Result<[ProductQuery], Error>)

    private let requestValue: RequestValue
    private let completion: (ResultValue) -> Void
    private let productsQueriesRepository: ProductsQueriesRepository

    init(
        requestValue: RequestValue,
        completion: @escaping (ResultValue) -> Void,
        productsQueriesRepository: ProductsQueriesRepository
    ) {

        self.requestValue = requestValue
        self.completion = completion
        self.productsQueriesRepository = productsQueriesRepository
    }
    
    func start() -> Cancellable? {

        self.productsQueriesRepository.fetchRecentsQueries(
            maxCount: requestValue.maxCount,
            completion: completion
        )
        return nil
    }
}
