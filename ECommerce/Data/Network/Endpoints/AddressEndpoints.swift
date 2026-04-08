//
//  AddressEndpoints.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import Foundation

enum AddressEndpoints {
    
    // MARK: - Create Address
    
    static func createAddress(with requestDTO: AddressRequestDTO) -> Endpoint<AddressResponseDTO> {
        return Endpoint(
            path: "api/v1/customer/addresses",
            method: .post,
            bodyParametersEncodable: requestDTO
        )
    }
    
    // MARK: - Update Address
    
    static func updateAddress(id: Int, with requestDTO: AddressRequestDTO) -> Endpoint<AddressResponseDTO> {
        return Endpoint(
            path: "api/v1/customer/addresses/\(id)",
            method: .put,
            bodyParametersEncodable: requestDTO
        )
    }
    
    // MARK: - Delete Address
    
    static func deleteAddress(id: Int) -> Endpoint<AddressDeleteResponseDTO> {
        return Endpoint(
            path: "api/v1/customer/addresses/\(id)",
            method: .delete
        )
    }
}
