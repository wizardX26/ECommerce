//
//  OrderProcessingViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderProcessingViewController: EcoViewController {
    
    @IBOutlet private weak var orderProcessingTableView: UITableView!
    
    private var orderProcessingController: OrderProcessingController! {
        get { controller as? OrderProcessingController }
    }
    
    // MARK: - Lifecycle
    
    static func create(
        with orderProcessingController: OrderProcessingController
    ) -> OrderProcessingViewController {
        let view = OrderProcessingViewController.instantiateViewController()
        view.controller = orderProcessingController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindOrderProcessingSpecific()
        setupNavigation()
        orderProcessingController.didLoad()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindOrderProcessingSpecific()
    }
    
    // MARK: - OrderProcessing-Specific Binding
    
    private func bindOrderProcessingSpecific() {
        orderProcessingController.items.observe(on: self) { [weak self] _ in
            self?.orderProcessingTableView.reloadData()
        }
    }
    
    // MARK: - Navigation
    
    private func setupNavigation() {
        if let controller = controller as? DefaultOrderProcessingController {
            controller.onSelectOrderItem = { [weak self] item in
                self?.navigateToOrderDetail(orderId: item.id)
            }
            controller.onBack = { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func navigateToOrderDetail(orderId: Int) {
        guard let navigationController = navigationController else { return }
        let appDIContainer = AppDIContainer()
        let orderDetailDIContainer = appDIContainer.makeOrderDetailDIContainer()
        let orderDetailVC = orderDetailDIContainer.makeOrderDetailViewController(orderId: orderId)
        
        // Setup cancel order success callback to remove from container
        if let orderDetailController = orderDetailVC.controller as? DefaultOrderDetailController,
           let orderContainerVC = findOrderContainerViewController() {
            orderDetailController.onCancelOrderSuccess = { [weak orderContainerVC] canceledOrderId in
                if let containerController = orderContainerVC?.orderContainerController as? DefaultOrderContainerController {
                    containerController.removeOrder(orderId: canceledOrderId)
                }
            }
        }
        
        navigationController.pushViewController(orderDetailVC, animated: true)
    }
    
    private func findOrderContainerViewController() -> OrderContainerViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if let orderContainerVC = responder as? OrderContainerViewController {
                return orderContainerVC
            }
        }
        return nil
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        orderProcessingTableView.delegate = self
        orderProcessingTableView.dataSource = self
        //orderProcessingTableView.register(cell: OrderProcessingCell.self)
        orderProcessingTableView.estimatedRowHeight = OrderProcessingCell.height
        orderProcessingTableView.rowHeight = UITableView.automaticDimension
    }
}

// MARK: - UITableViewDataSource

extension OrderProcessingViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderProcessingController.items.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: OrderProcessingCell = tableView.dequeueReusableCell(at: indexPath)
        
        // Guard để đảm bảo có data
        guard indexPath.row < orderProcessingController.items.value.count else {
            return cell
        }
        
        let item = orderProcessingController.items.value[indexPath.row]
        cell.fill(with: item)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension OrderProcessingViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        orderProcessingController.didSelectItem(at: indexPath.row)
    }
}
