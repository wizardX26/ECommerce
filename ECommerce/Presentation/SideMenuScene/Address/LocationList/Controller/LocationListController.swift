//
//  LocationListController.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation
import UIKit

protocol LocationListControllerInput {
    func viewDidLoad()
    func didSelectAddress(_ address: Address)
}

protocol LocationListControllerOutput {
    var addresses: Observable<[Address]> { get }
    var screenTitle: String { get }
    var onAddressSelected: ((Address) -> Void)? { get set }
}

typealias LocationListController = LocationListControllerInput & LocationListControllerOutput & EcoController

final class DefaultLocationListController: LocationListController {
    
    private let getAddressesUseCase: GetAddressesUseCase
    private let mainQueue: DispatchQueueType
    
    private var fetchTask: Cancellable? { willSet { fetchTask?.cancel() } }
    
    // MARK: - OUTPUT
    
    let addresses: Observable<[Address]> = Observable([])
    var screenTitle: String { "address".localized() }
    var onAddressSelected: ((Address) -> Void)?
    
    // MARK: - EcoController Output
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Navigation Bar Configuration
    
    var navigationBarTitle: String? {
        return self.screenTitle
    }
    
    var navigationBarRightItems: [EcoNavItem] {
        return [
            EcoNavItem.text(
                "Save",
                action: { [weak self] in
                    // Save action will be handled by parent
                    // For now, just dismiss or handle in view controller
                }
            )
        ]
    }
    
    var navigationBarBackground: EcoNavigationBackground {
        return .solid(.white)
    }
    
    var navigationBarBackgroundColor: UIColor? {
        return .white
    }
    
    var navigationBarButtonTintColor: UIColor? {
        return Colors.tokenRainbowBlueEnd
    }
    
    var navigationBarTitleColor: UIColor? {
        return .black
    }
    
    var navigationBarInitialHeight: CGFloat {
        return 80
    }
    
    var navigationBarCollapsedHeight: CGFloat {
        return 80
    }
    
    var navigationBarScrollBehavior: EcoNavigationScrollBehavior {
        return .sticky
    }
    
    // MARK: - Init
    
    init(
        getAddressesUseCase: GetAddressesUseCase,
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.getAddressesUseCase = getAddressesUseCase
        self.mainQueue = mainQueue
    }
    
    // MARK: - Private
    
    private func handle(error: Error) {
        let errorMessage = APIErrorParser.parseErrorMessage(from: error)
        let userFriendlyError = NSError(
            domain: "LocationListError",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        self.error.value = userFriendlyError
    }
}

// MARK: - INPUT Implementation

extension DefaultLocationListController {
    
    func viewDidLoad() {
        fetchAddresses()
    }
    
    func didSelectAddress(_ address: Address) {
        onAddressSelected?(address)
    }
    
    private func fetchAddresses() {
        loading.value = true
        error.value = nil
        
        fetchTask = getAddressesUseCase.execute { [weak self] result in
            self?.mainQueue.async {
                self?.loading.value = false
                
                switch result {
                case .success(let addresses):
                    self?.addresses.value = addresses
                case .failure(let error):
                    self?.handle(error: error)
                }
            }
        }
    }
}

// MARK: - EcoController Implementation

extension DefaultLocationListController {
    
    func onViewDidLoad() {
        navigationState.value = EcoNavigationState(
            title: navigationBarTitle,
            titleFont: navigationBarTitleFont,
            titleColor: navigationBarTitleColor,
            showsSearch: false,
            searchState: nil,
            leftItem: nil,
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
        // Refresh addresses when view appears
        fetchAddresses()
    }
    
    func onViewDidDisappear() {
        // Handle view did disappear if needed
    }
}