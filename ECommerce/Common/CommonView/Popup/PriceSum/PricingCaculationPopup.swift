//
//  PricingCaculationPopup.swift
//  MyKiot
//
//  Created by Nguyen Duc Hung on 19/6/25.
//

import UIKit

class PricingCaculationPopup: UIView {

    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var titlePricingLabel: UILabel!
    @IBOutlet weak var orderBreakdownLabel: UILabel!
    @IBOutlet weak var orderBreakdownValueLabel: UILabel!
    @IBOutlet weak var shippingLabel: UILabel!
    @IBOutlet weak var shippingValueLabel: UILabel!
    @IBOutlet weak var subTotalLabel: UILabel!
    @IBOutlet weak var subTotalValue: UILabel!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    @IBAction func didTapClosePopup(_ sender: Any) {
        self.dismiss()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("PricingCaculationPopup", owner: self, options: nil)
        self.contentView.frame = self.bounds
        self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(self.contentView)
        
        // Ensure contentView doesn't block touches to overlay
        contentView.isUserInteractionEnabled = true
    }
    
    func show(in parentView: UIView) {
        
        self.layer.cornerRadius = 16
        self.clipsToBounds = true
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        // Add semi-transparent background overlay
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.isUserInteractionEnabled = true
        overlayView.tag = 999 // Tag to identify overlay
        
        parentView.addSubview(overlayView)
        parentView.addSubview(self)
        
        // Add tap gesture to overlay to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        overlayView.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            // Overlay covers entire parent view
            overlayView.topAnchor.constraint(equalTo: parentView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            
            // Popup at bottom
            self.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 0),
            self.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: 0),
            self.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: 0),
            self.heightAnchor.constraint(equalToConstant: 444)
        ])
        
        // Animate appearance
        overlayView.alpha = 0
        self.transform = CGAffineTransform(translationX: 0, y: 444)
        
        UIView.animate(withDuration: 0.3) {
            overlayView.alpha = 1
            self.transform = .identity
        }
    }
    
    @objc private func overlayTapped() {
        dismiss()
    }
    
    @objc func dismiss() {
        // Find and remove overlay
        guard let superview = self.superview else { return }
        if let overlayView = superview.subviews.first(where: { $0.tag == 999 }) {
            UIView.animate(withDuration: 0.3, animations: {
                overlayView.alpha = 0
                self.transform = CGAffineTransform(translationX: 0, y: 444)
            }, completion: { _ in
                overlayView.removeFromSuperview()
                self.removeFromSuperview()
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(translationX: 0, y: 444)
            }, completion: { _ in
                self.removeFromSuperview()
            })
        }
    }
}

