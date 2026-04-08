//
//  FetchRecentLocationListQueriesUseCase.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

final class FetchRecentLocationListQueriesUseCase: UseCase {

    struct RequestValue {
        let maxCount: Int
    }
    typealias ResultValue = (Result<[LocationListQuery], Error>)

    private let requestValue: RequestValue
    private let completion: (ResultValue) -> Void
    private let locationListQueriesRepository: LocationListQueriesRepository

    init(
        requestValue: RequestValue,
        completion: @escaping (ResultValue) -> Void,
        locationListQueriesRepository: LocationListQueriesRepository
    ) {

        self.requestValue = requestValue
        self.completion = completion
        self.locationListQueriesRepository = locationListQueriesRepository
    }
    
    func start() -> Cancellable? {

        self.locationListQueriesRepository.fetchRecentsQueries(
            maxCount: requestValue.maxCount,
            completion: completion
        )
        return nil
    }
}
