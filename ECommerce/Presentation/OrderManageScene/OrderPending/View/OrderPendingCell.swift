//
//  OrderPendingCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderPendingCell: UITableViewCell {
    
    static let height = CGFloat(120)
    
    @IBOutlet private weak var orderIdLabel: UILabel!
    @IBOutlet private weak var paymentMethodLabel: UILabel!
    @IBOutlet private weak var totalAmountLabel: UILabel!
    @IBOutlet private weak var createdAtLabel: UILabel!
    
    private var item: OrderPendingItemModel?
    
    func fill(with item: OrderPendingItemModel) {
        self.item = item
        
        // Guard để tránh crash nếu outlet chưa được kết nối trong Storyboard
        guard let orderIdLabel = orderIdLabel,
              let paymentMethodLabel = paymentMethodLabel,
              let totalAmountLabel = totalAmountLabel,
              let createdAtLabel = createdAtLabel else {
            return
        }
        
        orderIdLabel.text = String(format: "order_number".localized(), "\(item.id)")
        paymentMethodLabel.text = String(format: "payment_label".localized(), item.formattedPaymentMethod)
        totalAmountLabel.text = item.formattedTotalAmount
        createdAtLabel.text = item.formattedDate
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        orderIdLabel?.text = nil
        paymentMethodLabel?.text = nil
        totalAmountLabel?.text = nil
        createdAtLabel?.text = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Alternate cell background colors - even rows white, odd rows systemGray6
        if let tableView = superview as? UITableView,
           let indexPath = tableView.indexPath(for: self) {
            backgroundColor = (indexPath.row % 2 == 0) ? .white : .systemGray6
        }
    }
}
