//
//  ProfileDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import UIKit

final class ProfileDIContainer {
    
    struct Dependencies {
        let apiDataTransferService: DataTransferService
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    // MARK: - Repositories
    
    func makeProfileRepository() -> ProfileRepository {
        DefaultProfileRepository(
            dataTransferService: dependencies.apiDataTransferService
        )
    }
    
    // MARK: - Use Cases
    
    func makeGetUserInfoUseCase() -> GetUserInfoUseCase {
        DefaultGetUserInfoUseCase(
            profileRepository: makeProfileRepository()
        )
    }
    
    func makeUpdateProfileUseCase() -> UpdateProfileUseCase {
        DefaultUpdateProfileUseCase(
            profileRepository: makeProfileRepository()
        )
    }
    
    func makeChangePasswordUseCase() -> ChangePasswordUseCase {
        DefaultChangePasswordUseCase(
            profileRepository: makeProfileRepository()
        )
    }
    
    // MARK: - Profile Scene
    
    func makeProfileViewController() -> ProfileViewController {
        ProfileViewController.create(
            with: makeProfileController()
        )
    }
    
    func makeProfileController() -> ProfileController {
        DefaultProfileController(
            getUserInfoUseCase: makeGetUserInfoUseCase()
        )
    }
    
    // MARK: - EditProfile Scene
    
    func makeEditProfileViewController(
        for fieldType: ProfileFieldType,
        screenTitle: String,
        currentValue: String
    ) -> EditProfileViewController {
        EditProfileViewController.create(
            with: makeEditProfileController(
                for: fieldType,
                screenTitle: screenTitle,
                currentValue: currentValue
            )
        )
    }
    
    func makeEditProfileController(
        for fieldType: ProfileFieldType,
        screenTitle: String,
        currentValue: String
    ) -> EditProfileController {
        return DefaultEditProfileController(
            fieldType: fieldType,
            screenTitle: screenTitle,
            currentValue: currentValue,
            updateProfileUseCase: fieldType != .changePassword ? makeUpdateProfileUseCase() : nil,
            changePasswordUseCase: fieldType == .changePassword ? makeChangePasswordUseCase() : nil
        )
    }
}
