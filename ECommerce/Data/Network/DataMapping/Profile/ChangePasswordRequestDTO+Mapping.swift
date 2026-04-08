//
//  ChangePasswordRequestDTO+Mapping.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

struct ChangePasswordRequestDTO: Encodable {
    let currentPassword: String
    let newPassword: String
    let newPasswordConfirmation: String
    
    enum CodingKeys: String, CodingKey {
        case currentPassword = "current_password"
        case newPassword = "new_password"
        case newPasswordConfirmation = "new_password_confirmation"
    }
}
