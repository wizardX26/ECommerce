//
//  OrderManageUseCase.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import Foundation

protocol OrderManageUseCase {
    @discardableResult
    func execute(
        completion: @escaping (Result<[OrderManage], Error>) -> Void
    ) -> Cancellable?
}

final class DefaultOrderManageUseCase: OrderManageUseCase {
    
    private let orderManageRepository: OrderManageRepository
    
    init(orderManageRepository: OrderManageRepository) {
        self.orderManageRepository = orderManageRepository
    }
    
    func execute(
        completion: @escaping (Result<[OrderManage], Error>) -> Void
    ) -> Cancellable? {
        return orderManageRepository.fetchOrders(completion: completion)
    }
}
