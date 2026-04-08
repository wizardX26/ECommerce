//
//  OrderDetailRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation

protocol OrderDetailRepository {
    @discardableResult
    func fetchOrderDetail(
        orderId: Int,
        completion: @escaping (Result<OrderDetail, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func cancelOrder(
        orderId: Int,
        completion: @escaping (Result<String, Error>) -> Void
    ) -> Cancellable?
}
