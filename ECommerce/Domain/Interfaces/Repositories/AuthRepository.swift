//
//  AuthRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

protocol AuthRepository {
    @discardableResult
    func signUp(
        fullName: String,
        email: String,
        phone: String,
        password: String,
        completion: @escaping (Result<AuthResult, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func login(
        phone: String,
        password: String,
        completion: @escaping (Result<AuthResult, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func refreshToken(
        refreshToken: String,
        completion: @escaping (Result<AuthSession, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func getUserInfo(
        completion: @escaping (Result<User, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func resendEmailVerification(
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable?
}
