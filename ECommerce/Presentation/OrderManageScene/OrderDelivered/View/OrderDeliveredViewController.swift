//
//  OrderDeliveredViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderDeliveredViewController: EcoViewController {
    
    @IBOutlet private weak var orderDeliveredTableView: UITableView!
    
    private var orderDeliveredController: OrderDeliveredController! {
        get { controller as? OrderDeliveredController }
    }
    
    // MARK: - Lifecycle
    
    static func create(
        with orderDeliveredController: OrderDeliveredController
    ) -> OrderDeliveredViewController {
        let view = OrderDeliveredViewController.instantiateViewController()
        view.controller = orderDeliveredController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindOrderDeliveredSpecific()
        setupNavigation()
        orderDeliveredController.didLoad()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindOrderDeliveredSpecific()
    }
    
    // MARK: - OrderDelivered-Specific Binding
    
    private func bindOrderDeliveredSpecific() {
        orderDeliveredController.items.observe(on: self) { [weak self] _ in
            self?.orderDeliveredTableView.reloadData()
        }
    }
    
    // MARK: - Navigation
    
    private func setupNavigation() {
        if let controller = controller as? DefaultOrderDeliveredController {
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
        orderDeliveredTableView.delegate = self
        orderDeliveredTableView.dataSource = self
        //orderDeliveredTableView.register(cell: OrderDeliveredCell.self)
        orderDeliveredTableView.estimatedRowHeight = OrderDeliveredCell.height
        orderDeliveredTableView.rowHeight = UITableView.automaticDimension
    }
}

// MARK: - UITableViewDataSource

extension OrderDeliveredViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderDeliveredController.items.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: OrderDeliveredCell = tableView.dequeueReusableCell(at: indexPath)
        
        // Guard để đảm bảo có data
        guard indexPath.row < orderDeliveredController.items.value.count else {
            return cell
        }
        
        let item = orderDeliveredController.items.value[indexPath.row]
        cell.fill(with: item)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension OrderDeliveredViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        orderDeliveredController.didSelectItem(at: indexPath.row)
    }
}
