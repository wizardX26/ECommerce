//
//  OrderManageRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation

protocol OrderManageRepository {
    @discardableResult
    func fetchOrders(
        completion: @escaping (Result<[OrderManage], Error>) -> Void
    ) -> Cancellable?
}
