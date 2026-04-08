//
//  OrderModel.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import Foundation

struct OrderModel {
    var cartItems: [CartItem] = []
    var address: String = ""
    var longitude: String = ""
    var latitude: String = ""
    var contactPersonName: String = ""
    var contactPersonNumber: String = ""
    var orderNote: String = ""
    var paymentCards: [PaymentCard] = []
    var selectedPaymentCard: PaymentCard?
    var defaultPaymentCard: PaymentCard?
}
