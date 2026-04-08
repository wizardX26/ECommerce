//
//  OrderContainerViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

class OrderContainerViewController: UIViewController {
    
    // MARK: - Properties
    
    private var segmentedPageContainer: SegmentedPageContainer!
    var orderContainerController: OrderContainerController!
    
    // View Controllers for each tab
    private var pendingViewController: OrderPendingViewController!
    private var processingViewController: OrderProcessingViewController!
    private var confirmedViewController: OrderConfirmedViewController!
    private var cancelViewController: OrderCancelViewController!
    private var deliveryViewController: OrderDeliveryViewController!
    private var deliveredViewController: OrderDeliveredViewController!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    // MARK: - Setup
    
    func configure(
        with orderContainerController: OrderContainerController,
        pendingController: OrderPendingController,
        processingController: OrderProcessingController,
        confirmedController: OrderConfirmedController,
        cancelController: OrderCancelController,
        deliveryController: OrderDeliveryController,
        deliveredController: OrderDeliveredController
    ) {
        self.orderContainerController = orderContainerController
        
        // Create view controllers
        pendingViewController = OrderPendingViewController.create(with: pendingController)
        processingViewController = OrderProcessingViewController.create(with: processingController)
        confirmedViewController = OrderConfirmedViewController.create(with: confirmedController)
        cancelViewController = OrderCancelViewController.create(with: cancelController)
        deliveryViewController = OrderDeliveryViewController.create(with: deliveryController)
        deliveredViewController = OrderDeliveredViewController.create(with: deliveredController)
        
        setupSegmentedPageContainer()
        bindOrders()
        orderContainerController.didLoad()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
    }
    
    private func setupSegmentedPageContainer() {
        segmentedPageContainer = SegmentedPageContainer()
        segmentedPageContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedPageContainer)
        
        NSLayoutConstraint.activate([
            segmentedPageContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            segmentedPageContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentedPageContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentedPageContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        segmentedPageContainer.configUI(
            titles: ["order_status_pending".localized(), "order_status_processing".localized(), "order_status_confirmed".localized(), "order_status_delivery".localized(), "order_status_delivered".localized(), "order_status_cancel".localized()],
            viewControllers: [
                pendingViewController,
                processingViewController,
                confirmedViewController,
                deliveryViewController,
                deliveredViewController,
                cancelViewController
            ],
            parent: self,
            defaultIndex: 0
        )
    }
    
    private func bindOrders() {
        orderContainerController.orders.observe(on: self) { [weak self] orders in
            guard let self = self else { return }
            
            // Update orders to each controller
            if let pendingController = self.pendingViewController.controller as? DefaultOrderPendingController {
                pendingController.updateOrders(orders)
            }
            if let processingController = self.processingViewController.controller as? DefaultOrderProcessingController {
                processingController.updateOrders(orders)
            }
            if let confirmedController = self.confirmedViewController.controller as? DefaultOrderConfirmedController {
                confirmedController.updateOrders(orders)
            }
            if let cancelController = self.cancelViewController.controller as? DefaultOrderCancelController {
                cancelController.updateOrders(orders)
            }
            if let deliveryController = self.deliveryViewController.controller as? DefaultOrderDeliveryController {
                deliveryController.updateOrders(orders)
            }
            if let deliveredController = self.deliveredViewController.controller as? DefaultOrderDeliveredController {
                deliveredController.updateOrders(orders)
            }
        }
    }
}

