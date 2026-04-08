//
//  OrderDetailAddressCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 16/1/26.
//

import UIKit

final class OrderDetailAddressCell: UITableViewCell {
    
    @IBOutlet weak var contactPersonNameLabel: UILabel!
    @IBOutlet weak var contactPersonNumberLabel: UILabel!
    @IBOutlet weak var addressDetailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    func fill(with address: ShippingAddress) {
        contactPersonNameLabel?.text = address.contactPersonName
        contactPersonNumberLabel?.text = address.contactPersonNumber
        addressDetailLabel?.text = address.addressDetail
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contactPersonNameLabel?.text = nil
        contactPersonNumberLabel?.text = nil
        addressDetailLabel?.text = nil
    }
}
