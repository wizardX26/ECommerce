//
//  CategoryUseCase.swift
//  ECommerce
//
//  Created by wizard.os25 on 7/1/26.
//

import Foundation

protocol CategoryUseCase {
    @discardableResult
    func execute(
        cached: @escaping ([Category]) -> Void,
        completion: @escaping (Result<[Category], Error>) -> Void
    ) -> Cancellable?
}

final class DefaultCategoryUseCase: CategoryUseCase {
    
    private let categoriesRepository: CategoriesRepository
    
    init(categoriesRepository: CategoriesRepository) {
        self.categoriesRepository = categoriesRepository
    }
    
    func execute(
        cached: @escaping ([Category]) -> Void,
        completion: @escaping (Result<[Category], Error>) -> Void
    ) -> Cancellable? {
        return categoriesRepository.fetchCategories(cached: cached, completion: completion)
    }
}
