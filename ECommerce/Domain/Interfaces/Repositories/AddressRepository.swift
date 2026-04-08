//
//  AddressRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import Foundation

protocol AddressRepository {
    @discardableResult
    func createAddress(
        contactPersonName: String,
        contactPersonNumber: String,
        addressDetail: String,
        countryId: Int,
        provinceId: Int,
        districtId: Int,
        wardId: Int,
        addressType: String,
        isDefault: Bool,
        completion: @escaping (Result<Address, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func updateAddress(
        id: Int,
        contactPersonName: String,
        contactPersonNumber: String,
        addressDetail: String,
        countryId: Int,
        provinceId: Int,
        districtId: Int,
        wardId: Int,
        addressType: String,
        isDefault: Bool,
        completion: @escaping (Result<Address, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func deleteAddress(
        id: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable?
}
