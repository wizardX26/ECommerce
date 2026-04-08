//
//  OrderDeliveryViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderDeliveryViewController: EcoViewController {
    
    @IBOutlet private weak var orderDeliveryTableView: UITableView!
    
    private var orderDeliveryController: OrderDeliveryController! {
        get { controller as? OrderDeliveryController }
    }
    
    // MARK: - Lifecycle
    
    static func create(
        with orderDeliveryController: OrderDeliveryController
    ) -> OrderDeliveryViewController {
        let view = OrderDeliveryViewController.instantiateViewController()
        view.controller = orderDeliveryController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindOrderDeliverySpecific()
        setupNavigation()
        orderDeliveryController.didLoad()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindOrderDeliverySpecific()
    }
    
    // MARK: - OrderDelivery-Specific Binding
    
    private func bindOrderDeliverySpecific() {
        orderDeliveryController.items.observe(on: self) { [weak self] _ in
            self?.orderDeliveryTableView.reloadData()
        }
    }
    
    // MARK: - Navigation
    
    private func setupNavigation() {
        if let controller = controller as? DefaultOrderDeliveryController {
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
        orderDeliveryTableView.delegate = self
        orderDeliveryTableView.dataSource = self
        //orderDeliveryTableView.register(cell: OrderDeliveryCell.self)
        orderDeliveryTableView.estimatedRowHeight = OrderDeliveryCell.height
        orderDeliveryTableView.rowHeight = UITableView.automaticDimension
    }
}

// MARK: - UITableViewDataSource

extension OrderDeliveryViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderDeliveryController.items.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: OrderDeliveryCell = tableView.dequeueReusableCell(at: indexPath)
        
        // Guard để đảm bảo có data
        guard indexPath.row < orderDeliveryController.items.value.count else {
            return cell
        }
        
        let item = orderDeliveryController.items.value[indexPath.row]
        cell.fill(with: item)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension OrderDeliveryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        orderDeliveryController.didSelectItem(at: indexPath.row)
    }
}
