//
//  LocationListEndpoints.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

enum LocationListEndpoints {
    
    // MARK: - Get Addresses
    
    static func getAddresses() -> Endpoint<LocationListResponseDTO> {
        return Endpoint(
            path: "api/v1/customer/addresses",
            method: .get
        )
    }
}
