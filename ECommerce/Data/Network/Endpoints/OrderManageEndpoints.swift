//
//  OrderManageEndpoints.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation

enum OrderManageEndpoints {
    
    // MARK: - Get Orders
    
    static func getOrders() -> Endpoint<OrderManageResponseDTO> {
        return Endpoint(
            path: "api/v1/orders/",
            method: .get
        )
    }
}
