//
//  ProfileController.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation
import UIKit

protocol ProfileControllerInput {
    func viewDidLoad()
    func didSelectCell(at section: Int, row: Int)
}

protocol ProfileControllerOutput {
    var user: Observable<User?> { get }
    var screenTitle: String { get }
    var onEditField: ((ProfileFieldType) -> Void)? { get set }
}

enum ProfileFieldType {
    case fullName
    case email
    case phone
    case changePassword
}

typealias ProfileController = ProfileControllerInput & ProfileControllerOutput & EcoController

final class DefaultProfileController: ProfileController {
    
    private let getUserInfoUseCase: GetUserInfoUseCase
    private let mainQueue: DispatchQueueType
    
    private var fetchTask: Cancellable? { willSet { fetchTask?.cancel() } }
    
    // MARK: - OUTPUT
    
    let user: Observable<User?> = Observable(nil)
    var screenTitle: String { "my_profile".localized() }
    var onEditField: ((ProfileFieldType) -> Void)?
    
    // MARK: - EcoController Output
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Navigation Bar Configuration
    
    var navigationBarTitle: String? {
        return self.screenTitle
    }
    
    var navigationBarLeftItem: EcoNavItem? {
        return EcoNavItem.back { [weak self] in
            self?.onNavigationBarLeftItemTap?()
        }
    }
    
    var navigationBarRightItems: [EcoNavItem] {
        return [
            EcoNavItem.icon(
                UIImage(systemName: "person.crop.circle.fill") ?? UIImage(),
                action: { [weak self] in
                    // Account action - to be implemented (will open popup)
                    self?.onAccountIconTap?()
                }
            )
        ]
    }
    
    var onAccountIconTap: (() -> Void)?
    
    var navigationBarBackground: EcoNavigationBackground {
        return .solid(.white)
    }
    
    var navigationBarBackgroundColor: UIColor? {
        return .white
    }
    
    var navigationBarButtonTintColor: UIColor? {
        return Colors.tokenDark100
    }
    
    var navigationBarTitleColor: UIColor? {
        return .black
    }
    
//    var navigationBarInitialHeight: CGFloat {
//        return 140
//    }
//    
//    var navigationBarCollapsedHeight: CGFloat {
//        return 80
//    }
    
    var navigationBarScrollBehavior: EcoNavigationScrollBehavior {
        return .sticky
    }
    
    // MARK: - Init
    
    init(
        getUserInfoUseCase: GetUserInfoUseCase,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.getUserInfoUseCase = getUserInfoUseCase
        self.mainQueue = mainQueue
    }
    
    // MARK: - Private
    
    private func handle(error: Error) {
        let errorMessage = APIErrorParser.parseErrorMessage(from: error)
        let userFriendlyError = NSError(
            domain: "ProfileError",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        self.error.value = userFriendlyError
    }
}

// MARK: - INPUT Implementation

extension DefaultProfileController {
    
    func viewDidLoad() {
        fetchUserInfo()
    }
    
    func didSelectCell(at section: Int, row: Int) {
        guard section == 0 else {
            // Section 1 (Shop Info) - to be implemented later
            return
        }
        
        let fieldType: ProfileFieldType
        switch row {
        case 0:
            fieldType = .fullName
        case 1:
            fieldType = .email
        case 2:
            fieldType = .phone
        case 3:
            fieldType = .changePassword
        default:
            return
        }
        
        onEditField?(fieldType)
    }
    
    private func fetchUserInfo() {
        loading.value = true
        error.value = nil
        
        fetchTask = getUserInfoUseCase.execute { [weak self] result in
            self?.mainQueue.async {
                self?.loading.value = false
                
                switch result {
                case .success(let user):
                    self?.user.value = user
                case .failure(let error):
                    self?.handle(error: error)
                }
            }
        }
    }
}

// MARK: - EcoController Implementation

extension DefaultProfileController {
    
    func onViewDidLoad() {
        navigationState.value = EcoNavigationState(
            title: navigationBarTitle,
            titleFont: navigationBarTitleFont,
            titleColor: navigationBarTitleColor,
            showsSearch: false,
            searchState: nil,
            leftItem: navigationBarLeftItem,
            rightItems: navigationBarRightItems,
            background: navigationBarBackground,
            backgroundColor: navigationBarBackgroundColor,
            buttonTintColor: navigationBarButtonTintColor,
            height: navigationBarInitialHeight,
            collapsedHeight: navigationBarCollapsedHeight,
            backButtonStyle: .simple,
            scrollBehavior: navigationBarScrollBehavior
        )
    }
    
    func onViewWillAppear() {
        // Refresh user info when view appears
        fetchUserInfo()
    }
    
    func onViewDidDisappear() {
        // Handle view did disappear if needed
    }
}