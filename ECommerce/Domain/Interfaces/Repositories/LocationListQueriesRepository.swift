//
//  LocationListQueriesRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

protocol LocationListQueriesRepository {
    func fetchRecentsQueries(
        maxCount: Int,
        completion: @escaping (Result<[LocationListQuery], Error>) -> Void
    )
    func saveRecentQuery(
        query: LocationListQuery,
        completion: @escaping (Result<LocationListQuery, Error>) -> Void
    )
}
