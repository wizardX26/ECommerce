//
//  LoginUseCase.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

protocol LoginUseCase {
    @discardableResult
    func execute(
        phone: String,
        password: String,
        completion: @escaping (Result<AuthResult, Error>) -> Void
    ) -> Cancellable?
}

final class DefaultLoginUseCase: LoginUseCase {
    
    private let authRepository: AuthRepository
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    func execute(
        phone: String,
        password: String,
        completion: @escaping (Result<AuthResult, Error>) -> Void
    ) -> Cancellable? {
        return authRepository.login(
            phone: phone,
            password: password,
            completion: completion
        )
    }
}
