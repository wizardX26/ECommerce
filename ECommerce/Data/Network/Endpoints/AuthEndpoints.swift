//
//  AuthEndpoints.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

enum AuthEndpoints {
    
    // MARK: - Sign Up
    
    static func signUp(with requestDTO: SignUpRequestDTO) -> Endpoint<SignUpResponseDTO> {
        return Endpoint(
            path: "api/v1/auth/register",
            method: .post,
            bodyParametersEncodable: requestDTO
        )
    }
    
    // MARK: - Login
    
    static func login(with requestDTO: LoginRequestDTO) -> Endpoint<LoginResponseDTO> {
        return Endpoint(
            path: "api/v1/auth/login",
            method: .post,
            bodyParametersEncodable: requestDTO
        )
    }
    
    // MARK: - Token Management
    
    static func refreshToken(with requestDTO: RefreshTokenRequestDTO) -> Endpoint<RefreshTokenResponseDTO> {
        return Endpoint(
            path: "api/v1/auth/refreshToken",
            method: .post,
            bodyParametersEncodable: requestDTO
        )
    }
    
    // MARK: - User Info
    
    static func getUserInfo() -> Endpoint<UserInfoResponseDTO> {
        return Endpoint(
            path: "api/v1/customer/info",
            method: .get
        )
    }
    
    // MARK: - Email Verification
    
    static func resendEmailVerification() -> Endpoint<Void> {
        return Endpoint(
            path: "api/v1/auth/email/verify/resend",
            method: .post
        )
    }
}
