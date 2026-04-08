//
//  EcoViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 8/1/26.
//

import UIKit

open class EcoViewController: EcoBaseViewController,
                              Alertable,
                              StoryboardInstantiable {

    // MARK: - Dependencies (late injection)

    public var controller: EcoController!

    // MARK: - Storyboard init

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()

        assert(controller != nil, "EcoController must be injected before viewDidLoad")

        bindCommon()
        controller.onViewDidLoad()
    }

    deinit {
        unbindCommon()
    }

    // MARK: - Common Binding

    open func bindCommon() {
        bindLoading()
        bindError()
        bindNavigation()
    }

    open func unbindCommon() {
        controller.loading.remove(observer: self)
        controller.error.remove(observer: self)
        controller.navigationState.remove(observer: self)
    }

    // MARK: - Binding Parts

    open func bindLoading() {
        controller.loading.observe(on: self) { [weak self] isLoading in
            self?.handleLoading(isLoading)
        }
    }

    open func bindError() {
        controller.error.observe(on: self) { [weak self] in
            self?.handleError($0) }
    }

    open func bindNavigation() {
        controller.navigationState.observe(on: self) { [weak self] state in
            print("🔵 [EcoViewController] Navigation state changed - Title: \(state.title ?? "nil"), LeftItem: \(state.leftItem != nil ? "EXISTS" : "nil"), RightItems: \(state.rightItems.count)")
            self?.applyNavigation(state)
        }
    }

    // MARK: - Handlers

    open func handleLoading(_ isLoading: Bool) {
        isLoading ? EcoLoadingView.show() : EcoLoadingView.hide()
    }

    open func handleError(_ error: Error?) {
        guard let error else { return }
        // Sử dụng APIErrorParser để có message thân thiện với người dùng
        let userFriendlyMessage = APIErrorParser.parseErrorMessage(from: error)
        showAlert(title: "error".localized(), message: userFriendlyMessage)
    }

    open func applyNavigation(_ state: EcoNavigationState) {
        print("🔵 [EcoViewController] applyNavigation called")
        print("   - navigationBarViewController: \(navigationBarViewController != nil ? "EXISTS" : "nil")")
        print("   - State leftItem: \(state.leftItem != nil ? "EXISTS" : "nil")")
        print("   - State rightItems: \(state.rightItems.count)")
        
        // Get callbacks from controller (using protocol extension defaults if not implemented)
        let callbacks = (
            onSearchTextChange: controller.onNavigationBarSearchTextChange,
            onSearchSubmit: controller.onNavigationBarSearchSubmit,
            onSearchClear: controller.onNavigationBarSearchClear,
            onLeftItemTap: controller.onNavigationBarLeftItemTap,
            onRightItemTap: controller.onNavigationBarRightItemTap,
            onCameraTap: controller.onNavigationBarCameraTap
        )
        print("📷 [EcoViewController] applyNavigation - onCameraTap callback: \(callbacks.onCameraTap != nil ? "EXISTS" : "nil")")
        
        if navigationBarViewController == nil {
            print("🔵 [EcoViewController] Attaching navigation bar for the first time")
            print("📷 [EcoViewController] onCameraTap callback before attach: \(callbacks.onCameraTap != nil ? "EXISTS" : "nil")")
            attachNavigationBar(
                initialState: state,
                onSearchTextChange: callbacks.onSearchTextChange,
                onSearchSubmit: callbacks.onSearchSubmit,
                onSearchClear: callbacks.onSearchClear,
                onLeftItemTap: callbacks.onLeftItemTap,
                onRightItemTap: callbacks.onRightItemTap,
                onCameraTap: callbacks.onCameraTap
            )
            print("✅ [EcoViewController] Navigation bar attached")
            // Verify callback was set
            if let navBarController = navigationBarViewController?.controller as? DefaultEcoNavigationBarController {
                print("📷 [EcoViewController] onCameraTap callback after attach: \(navBarController.onCameraTap != nil ? "EXISTS" : "nil")")
            }
        } else {
            print("🔵 [EcoViewController] Updating existing navigation bar")
            updateNavigationBar(state, animated: true)
            // Update callbacks after navigation bar is updated
            if let navBarController = navigationBarViewController?.controller as? DefaultEcoNavigationBarController {
                print("📷 [EcoViewController] onCameraTap callback before update: \(navBarController.onCameraTap != nil ? "EXISTS" : "nil")")
                navBarController.onSearchTextChange = callbacks.onSearchTextChange
                navBarController.onSearchSubmit = callbacks.onSearchSubmit
                navBarController.onSearchClear = callbacks.onSearchClear
                navBarController.onLeftItemTap = callbacks.onLeftItemTap
                navBarController.onRightItemTap = callbacks.onRightItemTap
                navBarController.onCameraTap = callbacks.onCameraTap
                print("📷 [EcoViewController] onCameraTap callback after update: \(navBarController.onCameraTap != nil ? "EXISTS" : "nil")")
                
                // Re-setup search field bindings sau khi callback được update
                if let navBarVC = navigationBarViewController {
                    navBarVC.updateSearchFieldBindings()
                    print("📷 [EcoViewController] Search field bindings updated after callback change")
                }
                
                print("✅ [EcoViewController] Navigation bar callbacks updated")
            }
        }
    }
}
