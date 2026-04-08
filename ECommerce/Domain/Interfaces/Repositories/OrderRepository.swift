//
//  OrderRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation

protocol OrderRepository {
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
