//
//  SplashController.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation
import UIKit

protocol SplashControllerInput {
    func checkAuthenticationStatus()
    func finishSplashAnimation()
}

protocol SplashControllerOutput {
    var shouldNavigateToMain: Observable<Bool> { get }
    var shouldNavigateToLogin: Observable<Bool> { get }
    var isAnimating: Observable<Bool> { get }
    var screenTitle: String { get }
}

typealias SplashController = SplashControllerInput & SplashControllerOutput & EcoController

final class DefaultSplashController: SplashController {
    
    private let utilities: Utilities
    private let mainQueue: DispatchQueueType
    
    // MARK: - OUTPUT
    
    let shouldNavigateToMain: Observable<Bool> = Observable(false)
    let shouldNavigateToLogin: Observable<Bool> = Observable(false)
    let isAnimating: Observable<Bool> = Observable(true)
    var screenTitle: String { "splash".localized() }
    
    // MARK: - EcoController Output (common to all controllers)
    
    let loading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    let navigationState: Observable<EcoNavigationState> = Observable(.init())
    
    // MARK: - Init
    
    init(
        utilities: Utilities = Utilities(),
        mainQueue: DispatchQueueType = DispatchQueue.main
    ) {
        self.utilities = utilities
        self.mainQueue = mainQueue
    }
    
    // MARK: - Input
    
    func checkAuthenticationStatus() {
        let isLoggedIn = utilities.isLoggedIn()
        
        // Wait for splash animation to complete before navigating
        mainQueue.asyncAfter(delay: 0.5) { [weak self] in
            guard let self = self else {
                return
            }
            self.finishSplashAnimation()
            
            // Trigger navigation based on login state
            if isLoggedIn {
                self.shouldNavigateToMain.value = true
            } else {
                self.shouldNavigateToLogin.value = true
            }
        }
    }
    
    func finishSplashAnimation() {
        isAnimating.value = false
    }
}

// MARK: - EcoController Lifecycle

extension DefaultSplashController {
    
    func onViewDidLoad() {
        // Initialize navigation state - splash screen typically doesn't show navigation bar
        navigationState.value = EcoNavigationState(
            title: nil,
            showsSearch: false,
            searchState: nil,
            leftItem: nil,
            rightItems: [],
            background: .transparent,
            height: 0,
            collapsedHeight: 0
        )
        
        // Start checking authentication status
        checkAuthenticationStatus()
    }
    
    func onViewWillAppear() {
        // Handle view will appear if needed
    }
    
    func onViewDidDisappear() {
        // Handle view did disappear if needed
    }
}
