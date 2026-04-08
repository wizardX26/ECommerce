//
//  CategoriesRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 7/1/26.
//

import Foundation

protocol CategoriesRepository {
    @discardableResult
    func fetchCategories(
        cached: @escaping ([Category]) -> Void,
        completion: @escaping (Result<[Category], Error>) -> Void
    ) -> Cancellable?
}
