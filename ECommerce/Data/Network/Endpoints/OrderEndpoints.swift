//
//  OrderEndpoints.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation

enum OrderEndpoints {
    
    // MARK: - Place Order
    
    static func placeOrder(with requestDTO: PlaceOrderRequestDTO) -> Endpoint<PlaceOrderResponseDTO> {
        return Endpoint(
            path: "api/v1/orders/place",
            method: .post,
            bodyParametersEncodable: requestDTO
        )
    }
}
