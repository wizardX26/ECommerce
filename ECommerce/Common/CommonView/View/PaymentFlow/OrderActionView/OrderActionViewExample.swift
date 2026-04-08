//
//  OrderActionViewExample.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//
//  This file demonstrates how to use OrderActionView in any ViewController

import UIKit

// MARK: - Example 1: Basic Usage

class BasicOrderActionExampleViewController: UIViewController {
    
    private var orderActionView: OrderActionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOrderActionView()
    }
    
    private func setupOrderActionView() {
        // Create the view
        orderActionView = OrderActionView()
        orderActionView.delegate = self
        orderActionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure appearance
        orderActionView.topLeftLabelText = "Subtotal"
        orderActionView.topRightLabelText = "$99.99"
        orderActionView.buttonTitle = "Place Order"
        orderActionView.leftItemType = .icon(UIImage(systemName: "cart.fill"))
        orderActionView.buttonWidth = 200 // Fixed width
        // OR
        // orderActionView.buttonMaxWidth = 300 // Maximum width
        
        // Add to view
        view.addSubview(orderActionView)
        
        // Setup constraints (e.g., bottom of screen)
        NSLayoutConstraint.activate([
            orderActionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.tokenSpacing24),
            orderActionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.tokenSpacing24),
            orderActionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.tokenSpacing16)
        ])
    }
}

extension BasicOrderActionExampleViewController: OrderActionViewDelegate {
    func orderActionViewDidTapAction(_ view: OrderActionView) {
        // Handle button tap
        print("Action button tapped")
        
        // Show loading
        view.isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            view.isLoading = false
            // Handle result
        }
    }
}

// MARK: - Example 2: Using Flow Coordinator (Recommended)

class FlowCoordinatorExampleViewController: UIViewController {
    
    private var orderActionView: OrderActionView!
    private var flowCoordinator: OrderActionFlowCoordinator!
    
    // Your order controller or use case
    private var orderController: OrderController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupOrderActionViewWithCoordinator()
    }
    
    private func setupOrderActionViewWithCoordinator() {
        // Create the view
        orderActionView = OrderActionView()
        orderActionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create flow coordinator
        flowCoordinator = OrderActionFlowCoordinator(orderActionView: orderActionView)
        flowCoordinator.delegate = self
        
        // Set initial state
        flowCoordinator.updateTotalAmount(99.99)
        flowCoordinator.setHasAddress(false) // User doesn't have address yet
        
        // Add to view
        view.addSubview(orderActionView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            orderActionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.tokenSpacing24),
            orderActionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.tokenSpacing24),
            orderActionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.tokenSpacing16)
        ])
    }
    
    // Example: After checking if user has address
    private func checkUserAddress() {
        // Check if user has address (from your address repository/use case)
        let hasAddress = true // Replace with actual check
        
        flowCoordinator.setHasAddress(hasAddress)
        
        if !hasAddress {
            flowCoordinator.updateState(.addressRequired)
        }
    }
    
    // Example: After order is placed
    private func handleOrderPlaced(_ order: Order) {
        flowCoordinator.updateState(.orderPlaced(order))
    }
}

extension FlowCoordinatorExampleViewController: OrderActionFlowCoordinatorDelegate {
    
    func orderActionFlowCoordinatorShouldPlaceOrder(_ coordinator: OrderActionFlowCoordinator) {
        // Place order via your OrderController
        guard let orderController = orderController else { return }
        
        coordinator.updateState(.processing)
        
        // Example: Call your order placement API
        orderController.didTapPlaceOrder(
            address: "123 Main St",
            longitude: "-122.4194",
            latitude: "37.7749",
            contactPersonName: "John Doe",
            contactPersonNumber: "+1234567890",
            orderNote: nil
        )
        
        // Observe order result
        orderController.isOrderPlaced.observe(on: self) { [weak self] isPlaced in
            if isPlaced, let order = orderController.orderResult.value {
                self?.flowCoordinator.updateState(.orderPlaced(order))
            }
        }
        
        orderController.error.observe(on: self) { [weak self] error in
            if let error = error {
                self?.flowCoordinator.updateState(.error(error))
                self?.flowCoordinator.delegate?.orderActionFlowCoordinator(self?.flowCoordinator ?? OrderActionFlowCoordinator(orderActionView: OrderActionView()), didEncounterError: error)
            }
        }
    }
    
    func orderActionFlowCoordinatorShouldAddAddress(_ coordinator: OrderActionFlowCoordinator) {
        // Navigate to add address screen
        // Example: Show AddressViewController
        let appDIContainer = AppDIContainer()
        let addressDIContainer = appDIContainer.makeAddressDIContainer()
        let addressVC = addressDIContainer.makeAddressViewController()
        
        // Setup callback when address is saved
        if let addressController = addressVC.controller as? DefaultAddressController {
            addressController.isSaveSuccess.observe(on: self) { [weak self] success in
                if success {
                    // Address saved, update coordinator
                    self?.flowCoordinator.setHasAddress(true)
                    self?.flowCoordinator.updateState(.initial)
                    
                    // Dismiss address screen
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
        
        navigationController?.pushViewController(addressVC, animated: true)
    }
    
    func orderActionFlowCoordinatorShouldCheckout(_ coordinator: OrderActionFlowCoordinator, order: Order) {
        // Initiate checkout/payment flow
        coordinator.updateState(.processing)
        
        // Example: Create payment intent
        // This would typically be done via PaymentCardUseCase
        // After payment intent is created, show Stripe PaymentSheet
        
        // For now, just show alert
        let alert = UIAlertController(
            title: "Checkout",
            message: "Proceed with payment for Order #\(order.orderId)?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            coordinator.updateState(.checkoutReady(order))
        })
        alert.addAction(UIAlertAction(title: "Pay", style: .default) { _ in
            // Process payment
            self.processPayment(for: order)
        })
        present(alert, animated: true)
    }
    
    func orderActionFlowCoordinator(_ coordinator: OrderActionFlowCoordinator, didEncounterError error: Error) {
        // Show error to user
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func processPayment(for order: Order) {
        // Implement payment processing
        // This would typically:
        // 1. Create payment intent via PaymentCardUseCase
        // 2. Show Stripe PaymentSheet
        // 3. Handle payment result
        // 4. Update coordinator state
    }
}

// MARK: - Example 3: Custom Configuration

class CustomConfigurationExampleViewController: UIViewController {
    
    private var orderActionView: OrderActionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomOrderActionView()
    }
    
    private func setupCustomOrderActionView() {
        orderActionView = OrderActionView()
        orderActionView.delegate = self
        orderActionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Custom configuration
        orderActionView.topLeftLabelText = "Items (3)"
        orderActionView.topRightLabelText = "$149.99"
        orderActionView.buttonTitle = "Proceed to Checkout"
        orderActionView.leftItemType = .label("Total:")
        orderActionView.buttonMinWidth = 150
        orderActionView.buttonMaxWidth = 250
        
        view.addSubview(orderActionView)
        
        NSLayoutConstraint.activate([
            orderActionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Spacing.tokenSpacing24),
            orderActionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Spacing.tokenSpacing24),
            orderActionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.tokenSpacing16)
        ])
    }
}

extension CustomConfigurationExampleViewController: OrderActionViewDelegate {
    func orderActionViewDidTapAction(_ view: OrderActionView) {
        // Handle action
    }
    
    func orderActionViewDidTapLeftItem(_ view: OrderActionView) {
        // Handle left item tap (e.g., show order summary)
        print("Left item tapped")
    }
}
