//
//  OrderConfirmedViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderConfirmedViewController: EcoViewController {
    
    @IBOutlet private weak var orderConfirmedTableView: UITableView!
    
    private var orderConfirmedController: OrderConfirmedController! {
        get { controller as? OrderConfirmedController }
    }
    
    // MARK: - Lifecycle
    
    static func create(
        with orderConfirmedController: OrderConfirmedController
    ) -> OrderConfirmedViewController {
        let view = OrderConfirmedViewController.instantiateViewController()
        view.controller = orderConfirmedController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindOrderConfirmedSpecific()
        setupNavigation()
        orderConfirmedController.didLoad()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindOrderConfirmedSpecific()
    }
    
    // MARK: - OrderConfirmed-Specific Binding
    
    private func bindOrderConfirmedSpecific() {
        orderConfirmedController.items.observe(on: self) { [weak self] _ in
            self?.orderConfirmedTableView.reloadData()
        }
    }
    
    // MARK: - Navigation
    
    private func setupNavigation() {
        if let controller = controller as? DefaultOrderConfirmedController {
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
        orderConfirmedTableView.delegate = self
        orderConfirmedTableView.dataSource = self
        //orderConfirmedTableView.register(cell: OrderConfirmedCell.self)
        orderConfirmedTableView.estimatedRowHeight = OrderConfirmedCell.height
        orderConfirmedTableView.rowHeight = UITableView.automaticDimension
    }
}

// MARK: - UITableViewDataSource

extension OrderConfirmedViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orderConfirmedController.items.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: OrderConfirmedCell = tableView.dequeueReusableCell(at: indexPath)
        
        // Guard để đảm bảo có data
        guard indexPath.row < orderConfirmedController.items.value.count else {
            return cell
        }
        
        let item = orderConfirmedController.items.value[indexPath.row]
        cell.fill(with: item)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension OrderConfirmedViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        orderConfirmedController.didSelectItem(at: indexPath.row)
    }
}
