//
//  OrderActionFlowCoordinator.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit
import Foundation

// MARK: - OrderActionFlowState

public enum OrderActionFlowState {
    case initial // Before order is placed
    case orderPlaced(Order) // Order created, ready for checkout
    case addressRequired // Need to add address first
    case checkoutReady(Order) // Ready to checkout
    case processing // API call in progress
    case error(Error) // Error occurred
}

// MARK: - OrderActionFlowCoordinatorDelegate

public protocol OrderActionFlowCoordinatorDelegate: AnyObject {
    /// Called when order should be placed
    func orderActionFlowCoordinatorShouldPlaceOrder(_ coordinator: OrderActionFlowCoordinator)
    
    /// Called when address should be added
    func orderActionFlowCoordinatorShouldAddAddress(_ coordinator: OrderActionFlowCoordinator)
    
    /// Called when checkout should be initiated
    func orderActionFlowCoordinatorShouldCheckout(_ coordinator: OrderActionFlowCoordinator, order: Order)
    
    /// Called when an error occurs
    func orderActionFlowCoordinator(_ coordinator: OrderActionFlowCoordinator, didEncounterError error: Error)
}

// MARK: - OrderActionFlowCoordinator

/// Coordinates the order flow: start order -> add address (if needed) -> checkout
public class OrderActionFlowCoordinator {
    
    // MARK: - Properties
    
    public weak var delegate: OrderActionFlowCoordinatorDelegate?
    public weak var orderActionView: OrderActionView?
    
    private var currentState: OrderActionFlowState = .initial {
        didSet {
            updateViewForState()
        }
    }
    
    private var currentOrder: Order?
    private var totalAmount: Double = 0.0
    private var hasAddress: Bool = false
    
    // MARK: - Initialization
    
    public init(orderActionView: OrderActionView) {
        self.orderActionView = orderActionView
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        orderActionView?.delegate = self
        updateViewForState()
    }
    
    // MARK: - Public Methods
    
    /// Update the coordinator with current order state
    public func updateState(_ state: OrderActionFlowState) {
        currentState = state
        
        switch state {
        case .orderPlaced(let order):
            currentOrder = order
            hasAddress = true
        case .addressRequired:
            hasAddress = false
        case .checkoutReady(let order):
            currentOrder = order
            hasAddress = true
        case .processing:
            orderActionView?.isLoading = true
        case .error:
            orderActionView?.isLoading = false
        case .initial:
            break
        }
    }
    
    /// Update total amount for display
    public func updateTotalAmount(_ amount: Double) {
        totalAmount = amount
        updateViewForState()
    }
    
    /// Set whether user has address
    public func setHasAddress(_ hasAddress: Bool) {
        self.hasAddress = hasAddress
        updateViewForState()
    }
    
    /// Reset to initial state
    public func reset() {
        currentState = .initial
        currentOrder = nil
        totalAmount = 0.0
        hasAddress = false
    }
    
    // MARK: - Private Methods
    
    private func updateViewForState() {
        guard let view = orderActionView else { return }
        
        switch currentState {
        case .initial:
            if hasAddress {
                // Ready to place order
                let formattedAmount = formatAmount(totalAmount)
                view.configureForStartOrder(
                    topLeftText: nil,
                    topRightText: formattedAmount,
                    buttonTitle: "Place Order",
                    leftItem: .none
                )
            } else {
                // Need address first
                view.configureForAddAddress(
                    topLeftText: "Address required",
                    topRightText: formatAmount(totalAmount),
                    buttonTitle: "Add Address",
                    leftItem: .icon(UIImage(systemName: "location.fill"))
                )
            }
            
        case .orderPlaced(let order):
            currentOrder = order
            let formattedAmount = formatAmount(order.totalAmount)
            view.configureForCheckout(
                topLeftText: "Order Total",
                topRightText: formattedAmount,
                buttonTitle: "Checkout",
                leftItem: .none
            )
            
        case .addressRequired:
            view.configureForAddAddress(
                topLeftText: "Address required",
                topRightText: formatAmount(totalAmount),
                buttonTitle: "Add Address",
                leftItem: .icon(UIImage(systemName: "location.fill"))
            )
            
        case .checkoutReady(let order):
            currentOrder = order
            let formattedAmount = formatAmount(order.totalAmount)
            view.configureForCheckout(
                topLeftText: "Total",
                topRightText: formattedAmount,
                buttonTitle: "Checkout",
                leftItem: .none
            )
            
        case .processing:
            view.isLoading = true
            view.isButtonEnabled = false
            
        case .error:
            view.isLoading = false
            view.isButtonEnabled = true
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
}

// MARK: - OrderActionViewDelegate

extension OrderActionFlowCoordinator: OrderActionViewDelegate {
    
    public func orderActionViewDidTapAction(_ view: OrderActionView) {
        switch currentState {
        case .initial:
            if hasAddress {
                // Place order
                delegate?.orderActionFlowCoordinatorShouldPlaceOrder(self)
            } else {
                // Add address
                delegate?.orderActionFlowCoordinatorShouldAddAddress(self)
            }
            
        case .orderPlaced(let order), .checkoutReady(let order):
            // Checkout
            delegate?.orderActionFlowCoordinatorShouldCheckout(self, order: order)
            
        case .addressRequired:
            // Add address
            delegate?.orderActionFlowCoordinatorShouldAddAddress(self)
            
        case .processing:
            // Do nothing while processing
            break
            
        case .error:
            // Retry based on previous state
            if let order = currentOrder {
                delegate?.orderActionFlowCoordinatorShouldCheckout(self, order: order)
            } else if hasAddress {
                delegate?.orderActionFlowCoordinatorShouldPlaceOrder(self)
            } else {
                delegate?.orderActionFlowCoordinatorShouldAddAddress(self)
            }
        }
    }
    
    public func orderActionViewDidTapLeftItem(_ view: OrderActionView) {
        // Left item tap can be used for additional actions
        // For example, show address list or payment method selection
        if case .addressRequired = currentState {
            delegate?.orderActionFlowCoordinatorShouldAddAddress(self)
        }
    }
}
