//
//  UpdateProfileRequestDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

struct UpdateProfileRequestDTO: Encodable {
    let fullName: String?
    let email: String?
    let phone: String?
    
    enum CodingKeys: String, CodingKey {
        case fullName // Backend now receives fullName (camelCase)
        case email
        case phone
    }
    
    init(fullName: String? = nil, email: String? = nil, phone: String? = nil) {
        self.fullName = fullName
        self.email = email
        self.phone = phone
    }
}
