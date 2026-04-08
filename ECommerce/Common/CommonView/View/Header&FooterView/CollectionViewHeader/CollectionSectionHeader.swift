//
//  SectionHeader.swift
//  MyKiot
//
//  Created by Nguyen Duc Hung on 11/6/25.
//

import UIKit

class CollectionSectionHeader: UICollectionReusableView {
   

    @IBOutlet weak var separatorDecorView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var chevronRightBtn: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.chevronRightBtn.setTitle("", for: .normal)
    }
    
    @IBAction func didTapChevronRightBtn(_ sender: Any) {
        
    }
}
