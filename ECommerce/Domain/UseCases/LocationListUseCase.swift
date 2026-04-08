//
//  LocationListUseCase.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

protocol GetAddressesUseCase {
    @discardableResult
    func execute(
        completion: @escaping (Result<[Address], Error>) -> Void
    ) -> Cancellable?
}

final class DefaultGetAddressesUseCase: GetAddressesUseCase {
    
    private let locationListRepository: LocationListRepository
    
    init(locationListRepository: LocationListRepository) {
        self.locationListRepository = locationListRepository
    }
    
    func execute(
        completion: @escaping (Result<[Address], Error>) -> Void
    ) -> Cancellable? {
        return locationListRepository.getAddresses(completion: completion)
    }
}
