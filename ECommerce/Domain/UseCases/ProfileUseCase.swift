//
//  ProfileUseCase.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

protocol GetUserInfoUseCase {
    @discardableResult
    func execute(
        completion: @escaping (Result<User, Error>) -> Void
    ) -> Cancellable?
}

protocol UpdateProfileUseCase {
    @discardableResult
    func execute(
        fName: String?,
        email: String?,
        phone: String?,
        completion: @escaping (Result<User, Error>) -> Void
    ) -> Cancellable?
}

protocol ChangePasswordUseCase {
    @discardableResult
    func execute(
        currentPassword: String,
        newPassword: String,
        newPasswordConfirmation: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable?
}

final class DefaultGetUserInfoUseCase: GetUserInfoUseCase {
    
    private let profileRepository: ProfileRepository
    
    init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }
    
    func execute(
        completion: @escaping (Result<User, Error>) -> Void
    ) -> Cancellable? {
        return profileRepository.getUserInfo(completion: completion)
    }
}

final class DefaultUpdateProfileUseCase: UpdateProfileUseCase {
    
    private let profileRepository: ProfileRepository
    
    init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }
    
    func execute(
        fName: String?,
        email: String?,
        phone: String?,
        completion: @escaping (Result<User, Error>) -> Void
    ) -> Cancellable? {
        return profileRepository.updateProfile(
            fName: fName,
            email: email,
            phone: phone,
            completion: completion
        )
    }
}

final class DefaultChangePasswordUseCase: ChangePasswordUseCase {
    
    private let profileRepository: ProfileRepository
    
    init(profileRepository: ProfileRepository) {
        self.profileRepository = profileRepository
    }
    
    func execute(
        currentPassword: String,
        newPassword: String,
        newPasswordConfirmation: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) -> Cancellable? {
        return profileRepository.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
            newPasswordConfirmation: newPasswordConfirmation,
            completion: completion
        )
    }
}
