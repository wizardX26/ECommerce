//
//  DescripSectionHeader.swift
//  MyKiot
//
//  Created by Nguyen Duc Hung on 18/6/25.
//

import UIKit

class CollectionDescripSectionHeader: UICollectionReusableView {
  
    
    @IBOutlet weak var separatorDecorView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var chevronRightBtn: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.separatorDecorView.backgroundColor = .opaqueSeparator
        self.chevronRightBtn.setTitle("", for: .normal)
    }
    
    @IBAction func didTapChevronRightBtn(_ sender: Any) {
        
    }
}
