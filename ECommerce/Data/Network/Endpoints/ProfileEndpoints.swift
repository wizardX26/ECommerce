//
//  ProfileEndpoints.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

enum ProfileEndpoints {
    
    // MARK: - Get User Info
    
    static func getUserInfo() -> Endpoint<UserInfoResponseDTO> {
        return Endpoint(
            path: "api/v1/customer/info",
            method: .get
        )
    }
    
    // MARK: - Update Profile
    
    static func updateProfile(with requestDTO: UpdateProfileRequestDTO) -> Endpoint<UpdateProfileResponseDTO> {
        return Endpoint(
            path: "api/v1/customer/update-profile",
            method: .post,
            bodyParametersEncodable: requestDTO
        )
    }
    
    // MARK: - Change Password
    
    static func changePassword(with requestDTO: ChangePasswordRequestDTO) -> Endpoint<ChangePasswordResponseDTO> {
        return Endpoint(
            path: "api/v1/customer/change-password",
            method: .post,
            bodyParametersEncodable: requestDTO
        )
    }
}
