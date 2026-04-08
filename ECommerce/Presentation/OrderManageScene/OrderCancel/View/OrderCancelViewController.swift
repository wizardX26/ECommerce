//
//  OrderCancelViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderCancelViewController: EcoViewController {
    
    @IBOutlet private weak var orderCancelTableView: UITableView!
    
    private var orderCancelController: OrderCancelController! {
        get { controller as? OrderCancelController }
    }
    
    // MARK: - Lifecycle
    
    static func create(
        with orderCancelController: OrderCancelController
    ) -> OrderCancelViewController {
        let view = OrderCancelViewController.instantiateViewController()
        view.controller = orderCancelController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindOrderCancelSpecific()
        setupNavigation()
        orderCancelController.didLoad()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindOrderCancelSpecific()
    }
    
    // MARK: - OrderCancel-Specific Binding
    
    private func bindOrderCancelSpecific() {
        orderCancelController.items.observe(on: self) { [weak self] _ in
            self?.orderCancelTableView.reloadData()
        }
    }
    
    // MARK: - Navigation
    
    private func setupNavigation() {
        if let controller = controller as? DefaultOrderCancelController {
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
        orderCancelTableView.delegate = self
        orderCancelTableView.dataSource = self
        //orderCancelTableView.register(cell: OrderCancelCell.self)
        orderCancelTableView.estimatedRowHeight = OrderCancelCell.height
        orderCancelTableView.rowHeight = UITableView.automaticDimension
    }
}

// MARK: - UITableViewDataSource

extension OrderCancelViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderCancelController.items.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: OrderCancelCell = tableView.dequeueReusableCell(at: indexPath)
        
        // Guard để đảm bảo có data
        guard indexPath.row < orderCancelController.items.value.count else {
            return cell
        }
        
        let item = orderCancelController.items.value[indexPath.row]
        cell.fill(with: item)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension OrderCancelViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        orderCancelController.didSelectItem(at: indexPath.row)
    }
}
