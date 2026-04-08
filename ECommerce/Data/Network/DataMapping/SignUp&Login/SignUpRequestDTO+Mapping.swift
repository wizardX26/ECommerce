//
//  SignUpRequestDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

struct SignUpRequestDTO: Encodable {
    let fullName: String
    let email: String
    let phone: String
    let password: String
    
    enum CodingKeys: String, CodingKey {
        case fullName = "f_name"
        case email, phone, password
    }
}
