//
//  DefaultAddressRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import Foundation

final class DefaultAddressRepository {
    
    private let dataTransferService: DataTransferService
    private let backgroundQueue: DataTransferDispatchQueue
    
    init(
        dataTransferService: DataTransferService,
        backgroundQueue: DataTransferDispatchQueue = DispatchQueue.global(qos: .userInitiated)
    ) {
        self.dataTransferService = dataTransferService
        self.backgroundQueue = backgroundQueue
    }
}

extension DefaultAddressRepository: AddressRepository {
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
    ) -> Cancellable? {
        // Address type values must match backend keys exactly: "shipping", "shop", "other"
        // No mapping needed - send as is
        print("📍 [AddressRepository] createAddress - addressType: '\(addressType)' (sending as is)")
        print("📍 [AddressRepository] createAddress - defaultShipping: \(isDefault)")
        
        let requestDTO = AddressRequestDTO(
            contactPersonName: contactPersonName,
            contactPersonNumber: contactPersonNumber,
            addressDetail: addressDetail,
            countryId: countryId,
            provinceId: provinceId,
            districtId: districtId,
            wardId: wardId,
            addressType: addressType, // Send exact value: "shipping", "shop", or "other"
            defaultShipping: isDefault
        )
        
        // Debug: Print encoded request
        if let jsonData = try? JSONEncoder().encode(requestDTO),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📍 [AddressRepository] Request DTO JSON: \(jsonString)")
        }
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = AddressEndpoints.createAddress(with: requestDTO)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                completion(.success(responseDTO.toDomain()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
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
    ) -> Cancellable? {
        print("📍 [AddressRepository] updateAddress - id: \(id), addressType: '\(addressType)'")
        
        let requestDTO = AddressRequestDTO(
            contactPersonName: contactPersonName,
            contactPersonNumber: contactPersonNumber,
            addressDetail: addressDetail,
            countryId: countryId,
            provinceId: provinceId,
            districtId: districtId,
            wardId: wardId,
            addressType: addressType,
            defaultShipping: isDefault
        )
        
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = AddressEndpoints.updateAddress(id: id, with: requestDTO)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success(let responseDTO):
                completion(.success(responseDTO.toDomain()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
    
    func deleteAddress(
        id: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable? {
        print("📍 [AddressRepository] deleteAddress - id: \(id)")
        
        let task = RepositoryTask()
        
        guard !task.isCancelled else { return nil }
        
        let endpoint = AddressEndpoints.deleteAddress(id: id)
        task.networkTask = dataTransferService.request(
            with: endpoint,
            on: backgroundQueue
        ) { result in
            guard !task.isCancelled else { return }
            
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        return task
    }
}
