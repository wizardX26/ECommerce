//
//  OrderUseCase.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation

protocol OrderUseCase {
    func placeOrder(
        cart: [CartItem],
        orderNote: String?,
        deliveryAddressId: Int?,
        addressDetail: String?,
        countryId: Int?,
        provinceId: Int?,
        districtId: Int?,
        wardId: Int?,
        contactPersonName: String?,
        contactPersonNumber: String?,
        completion: @escaping (Result<Order, Error>) -> Void
    ) -> Cancellable?
}

final class DefaultOrderUseCase: OrderUseCase {
    
    private let orderRepository: OrderRepository
    
    init(orderRepository: OrderRepository) {
        self.orderRepository = orderRepository
    }
    
    func placeOrder(
        cart: [CartItem],
        orderNote: String?,
        deliveryAddressId: Int?,
        addressDetail: String?,
        countryId: Int?,
        provinceId: Int?,
        districtId: Int?,
        wardId: Int?,
        contactPersonName: String?,
        contactPersonNumber: String?,
        completion: @escaping (Result<Order, Error>) -> Void
    ) -> Cancellable? {
        return orderRepository.placeOrder(
            cart: cart,
            orderNote: orderNote,
            deliveryAddressId: deliveryAddressId,
            addressDetail: addressDetail,
            countryId: countryId,
            provinceId: provinceId,
            districtId: districtId,
            wardId: wardId,
            contactPersonName: contactPersonName,
            contactPersonNumber: contactPersonNumber,
            completion: completion
        )
    }
}
