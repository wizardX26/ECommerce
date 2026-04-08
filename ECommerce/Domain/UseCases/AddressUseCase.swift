//
//  AddressUseCase.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import Foundation

protocol CreateAddressUseCase {
    @discardableResult
    func execute(
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
}

protocol UpdateAddressUseCase {
    @discardableResult
    func execute(
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
}

protocol DeleteAddressUseCase {
    @discardableResult
    func execute(
        id: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable?
}

final class DefaultCreateAddressUseCase: CreateAddressUseCase {
    
    private let addressRepository: AddressRepository
    
    init(addressRepository: AddressRepository) {
        self.addressRepository = addressRepository
    }
    
    func execute(
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
    ) -> Cancellable? {
        return addressRepository.createAddress(
            contactPersonName: contactPersonName,
            contactPersonNumber: contactPersonNumber,
            addressDetail: addressDetail,
            countryId: countryId,
            provinceId: provinceId,
            districtId: districtId,
            wardId: wardId,
            addressType: addressType,
            isDefault: isDefault,
            completion: completion
        )
    }
}

final class DefaultUpdateAddressUseCase: UpdateAddressUseCase {
    
    private let addressRepository: AddressRepository
    
    init(addressRepository: AddressRepository) {
        self.addressRepository = addressRepository
    }
    
    func execute(
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
    ) -> Cancellable? {
        return addressRepository.updateAddress(
            id: id,
            contactPersonName: contactPersonName,
            contactPersonNumber: contactPersonNumber,
            addressDetail: addressDetail,
            countryId: countryId,
            provinceId: provinceId,
            districtId: districtId,
            wardId: wardId,
            addressType: addressType,
            isDefault: isDefault,
            completion: completion
        )
    }
}

final class DefaultDeleteAddressUseCase: DeleteAddressUseCase {
    
    private let addressRepository: AddressRepository
    
    init(addressRepository: AddressRepository) {
        self.addressRepository = addressRepository
    }
    
    func execute(
        id: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable? {
        return addressRepository.deleteAddress(
            id: id,
            completion: completion
        )
    }
}
