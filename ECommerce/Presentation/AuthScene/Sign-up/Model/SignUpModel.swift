//
//  SignUpModel.swift
//  MyKiot
//
//  Created by wizard.os25 on 24/11/25.
//

import Foundation

// MARK: - Sign Up Request
struct SignUpModel: Codable {
    let fullName: String
    let email: String
    let phone: String
    let password: String
    
    enum CodingKeys: String, CodingKey {
        case fullName, email, phone, password
    }
}

