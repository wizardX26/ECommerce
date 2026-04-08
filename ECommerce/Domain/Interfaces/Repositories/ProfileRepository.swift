//
//  ProfileRepository.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

protocol ProfileRepository {
    @discardableResult
    func getUserInfo(
        completion: @escaping (Result<User, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func updateProfile(
        fName: String?,
        email: String?,
        phone: String?,
        completion: @escaping (Result<User, Error>) -> Void
    ) -> Cancellable?
    
    @discardableResult
    func changePassword(
        currentPassword: String,
        newPassword: String,
        newPasswordConfirmation: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable?
}
