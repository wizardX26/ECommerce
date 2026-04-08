//
//  LoginRequestDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

struct LoginRequestDTO: Encodable {
    let phone: String
    let password: String
}
