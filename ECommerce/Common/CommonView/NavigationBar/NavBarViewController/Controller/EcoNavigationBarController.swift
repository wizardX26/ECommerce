//
//  EcoNavigationBarController.swift
//  ECommerce
//
//  Created by wizard.os25 on 8/1/26.
//

import UIKit

// MARK: - Navigation Bar Controller Input Protocol

public protocol EcoNavigationBarControllerInput {
    func viewDidLoad()
    func didUpdateState(_ state: EcoNavigationState)
    func didSearchTextChange(_ text: String)
    func didSearchSubmit(_ text: String)
    func didSearchClear()
    func didLeftItemTap()
    func didRightItemTap(at index: Int)
    func didScrollUpdate(progress: CGFloat)
}

// MARK: - Navigation Bar Controller Output Protocol

public protocol EcoNavigationBarControllerOutput {
    var state: Observable<EcoNavigationState> { get }
    var statusBarStyle: Observable<UIStatusBarStyle> { get }
}

// MARK: - Navigation Bar Controller Typealias

public typealias EcoNavigationBarController = EcoNavigationBarControllerInput & EcoNavigationBarControllerOutput

// MARK: - Default Navigation Bar Controller

public final class DefaultEcoNavigationBarController: EcoNavigationBarController {
    
    // MARK: - OUTPUT
    
    public let state: Observable<EcoNavigationState>
    public let statusBarStyle: Observable<UIStatusBarStyle>
    
    // MARK: - Callbacks
    
    public var onSearchTextChange: ((String) -> Void)?
    public var onSearchSubmit: ((String) -> Void)?
    public var onSearchClear: (() -> Void)?
    public var onLeftItemTap: (() -> Void)?
    public var onRightItemTap: ((Int) -> Void)?
    public var onCameraTap: (() -> Void)?
    
    // MARK: - Private
    
    private var _currentState: EcoNavigationState
    private var _isUpdatingTextOnly = false
    
    private var currentState: EcoNavigationState {
        get { _currentState }
        set {
            _currentState = newValue
            // Chỉ trigger state change nếu không phải chỉ update search text
            // Để tránh reset navigation bar khi user đang nhập
            if !_isUpdatingTextOnly {
                state.value = newValue
                updateStatusBarStyle()
            }
        }
    }
    
    // MARK: - Init
    
    public init(initialState: EcoNavigationState = .init()) {
        self._currentState = initialState
        self.state = Observable(initialState)
        self.statusBarStyle = Observable(.darkContent)
        updateStatusBarStyle()
    }
    
    // MARK: - Private Helpers
    
    private func updateStatusBarStyle() {
        let style: UIStatusBarStyle
        switch _currentState.background {
        case .transparent:
            style = .lightContent
        default:
            style = .darkContent
        }
        statusBarStyle.value = style
    }
    
    private func updateSearchState(_ updateBlock: (inout EcoSearchState) -> Void) {
        var searchState = _currentState.searchState ?? EcoSearchState()
        updateBlock(&searchState)
        _currentState.searchState = searchState
        // Trigger state change nếu không phải text only update
        if !_isUpdatingTextOnly {
            currentState = _currentState
        }
    }
}

// MARK: - INPUT Implementation

extension DefaultEcoNavigationBarController {
    
    public func viewDidLoad() {
        // Initial setup if needed
    }
    
    public func didUpdateState(_ newState: EcoNavigationState) {
        currentState = newState
    }
    
    public func didSearchTextChange(_ text: String) {
        // Update text trong state mà không trigger state change
        // Bằng cách set flag _isUpdatingTextOnly
        _isUpdatingTextOnly = true
        if _currentState.searchState == nil {
            _currentState.searchState = EcoSearchState()
        }
        _currentState.searchState?.text = text
        _isUpdatingTextOnly = false
        // Không trigger state.value = currentState để tránh render lại navigation bar
        
        onSearchTextChange?(text)
    }
    
    public func didSearchSubmit(_ text: String) {
        // Khi submit search, chỉ update text trong state mà không trigger state change
        // Để giữ nguyên trạng thái navigation bar (text field vẫn hiển thị)
        // textField sẽ tự động resignFirstResponder trong textFieldShouldReturn
        _isUpdatingTextOnly = true
        if _currentState.searchState == nil {
            _currentState.searchState = EcoSearchState()
        }
        _currentState.searchState?.text = text
        // Giữ nguyên isEditing = true để text field vẫn hiển thị
        _currentState.searchState?.isEditing = true
        _isUpdatingTextOnly = false
        // Không trigger state.value = currentState để tránh render lại navigation bar
        
        onSearchSubmit?(text)
    }
    
    public func didSearchClear() {
        updateSearchState { 
            $0.text = ""
            $0.isEditing = false
        }
        onSearchClear?()
    }
    
    public func didLeftItemTap() {
        guard _currentState.leftItem != nil else { return }
        // Note: Action from state is already executed in ButtonActionWrapper
        // Only call the callback here, not the action again
        onLeftItemTap?()
    }
    
    public func didRightItemTap(at index: Int) {
        guard index < _currentState.rightItems.count else { return }
        // Note: Action from state is already executed in ButtonActionWrapper
        // Only call the callback here, not the action again
        onRightItemTap?(index)
    }
    
    public func didScrollUpdate(progress: CGFloat) {
        // Handle scroll updates if needed for state changes
        // The view will handle the actual scroll behavior rendering
    }
}

// MARK: - Convenience Methods

public extension DefaultEcoNavigationBarController {
    
    func setTitle(_ title: String?) {
        var newState = _currentState
        newState.title = title
        currentState = newState
    }
    
    func showSearch(_ show: Bool) {
        var newState = _currentState
        newState.showsSearch = show
        currentState = newState
    }
    
    func setBackground(_ background: EcoNavigationBackground) {
        var newState = _currentState
        newState.background = background
        currentState = newState
    }
    
    func setLeftItem(_ item: EcoNavItem?) {
        var newState = _currentState
        newState.leftItem = item
        currentState = newState
    }
    
    func setRightItems(_ items: [EcoNavItem]) {
        var newState = _currentState
        newState.rightItems = items
        currentState = newState
    }
    
    func update(_ block: (inout EcoNavigationState) -> Void) {
        var newState = _currentState
        block(&newState)
        currentState = newState
    }
}
