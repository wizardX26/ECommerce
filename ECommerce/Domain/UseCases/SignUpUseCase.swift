//
//  SignUpUseCase.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

protocol SignUpUseCase {
    @discardableResult
    func execute(
        fullName: String,
        email: String,
        phone: String,
        password: String,
        completion: @escaping (Result<AuthResult, Error>) -> Void
    ) -> Cancellable?
}

final class DefaultSignUpUseCase: SignUpUseCase {
    
    private let authRepository: AuthRepository
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    func execute(
        fullName: String,
        email: String,
        phone: String,
        password: String,
        completion: @escaping (Result<AuthResult, Error>) -> Void
    ) -> Cancellable? {
        return authRepository.signUp(
            fullName: fullName,
            email: email,
            phone: phone,
            password: password,
            completion: completion
        )
    }
}
