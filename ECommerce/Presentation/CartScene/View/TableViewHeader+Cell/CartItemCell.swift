//
//  CartItemCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 17/1/26.
//

import UIKit

class CartItemCell: UITableViewCell {
    
    @IBOutlet weak var onChooseButton: UIButton!
    @IBOutlet weak var cartItemImageView: UIImageView!
    @IBOutlet weak var cartItemTitleLabel: UILabel!
    @IBOutlet weak var cartItemDescLabel: UILabel!
    @IBOutlet weak var cartItemAmountLabel: UILabel!
    @IBOutlet weak var cartItemDeleteButton: UIButton!
    @IBOutlet weak var cartItemTextField: UITextField!
    
    // Quantity controls
    private var minusButton: UIButton!
    private var plusButton: UIButton!
    
    // Current item
    private var currentItem: CartItemModel?
    
    // Callbacks
    var onToggleSelection: (() -> Void)?
    var onQuantityChanged: ((Int) -> Void)?
    var onDelete: (() -> Void)?
    
    private let imageCache = DefaultImageCacheService.shared
    private var currentQuantity: Int = 1 {
        didSet {
            cartItemTextField.text = "\(currentQuantity)"
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        setupQuantityControls()
        setupViews()
        
        onChooseButton.addTarget(self, action: #selector(chooseButtonTapped), for: .touchUpInside)
        cartItemDeleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        cartItemTextField.delegate = self
        cartItemTextField.keyboardType = .numberPad
    }
    
    private func setupViews() {
        // Image view - fit to frame, không tràn khỏi khung
        cartItemImageView?.contentMode = .scaleAspectFit
        cartItemImageView?.clipsToBounds = true // Clip để image không tràn
        cartItemImageView?.layer.cornerRadius = 8
        cartItemImageView?.backgroundColor = .systemGray6
        
        // Title label - bold
        cartItemTitleLabel?.font = Typography.fontBold16
        cartItemTitleLabel?.textColor = Colors.tokenDark100
        
        // Description label - small and light gray
        cartItemDescLabel?.numberOfLines = 2
        cartItemDescLabel?.font = Typography.fontRegular12
        cartItemDescLabel?.textColor = UIColor.systemGray
        
        // Amount label - will format with VND in configure
        cartItemAmountLabel?.font = Typography.fontMedium14
        cartItemAmountLabel?.textColor = Colors.tokenDark100
    }
    
    private func setupQuantityControls() {
        guard let textField = cartItemTextField else { return }
        
        // Configure existing textField
        textField.textAlignment = .center
        textField.font = Typography.fontMedium14
        //textField.backgroundColor = .systemGray4
        textField.borderStyle = .none
        textField.layer.cornerRadius = 0
        
        // Store original constraints
        guard let textFieldSuperview = textField.superview else { return }
        
        // Find textField's trailing constraint to delete button
        var trailingConstraint: NSLayoutConstraint?
        for constraint in textFieldSuperview.constraints {
            if constraint.firstItem === textField && constraint.firstAttribute == .trailing {
                if let secondItem = constraint.secondItem as? UIButton, secondItem === cartItemDeleteButton {
                    trailingConstraint = constraint
                    break
                }
            }
        }
        
        // Create container view for quantity controls
        let containerView = UIView()
        containerView.backgroundColor = Colors.tokenDark10
        containerView.layer.cornerRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        textFieldSuperview.addSubview(containerView)
        
        // Create minus button
        minusButton = UIButton(type: .system)
        minusButton.setTitle("-", for: .normal)
        minusButton.titleLabel?.font = Typography.fontBold18
        minusButton.setTitleColor(Colors.tokenDark100, for: .normal)
        minusButton.translatesAutoresizingMaskIntoConstraints = false
        minusButton.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)
        containerView.addSubview(minusButton)
        
        // Create plus button
        plusButton = UIButton(type: .system)
        plusButton.setTitle("+", for: .normal)
        plusButton.titleLabel?.font = Typography.fontBold18
        plusButton.setTitleColor(Colors.tokenDark100, for: .normal)
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
        containerView.addSubview(plusButton)
        
        // Move textField to container
        textField.removeFromSuperview()
        containerView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // Remove old textField constraints and add new ones
        if let trailing = trailingConstraint {
            trailing.isActive = false
        }
        
        // Constraints for container (same position as textField was)
        NSLayoutConstraint.activate([
            // Container view (same position as textField)
            containerView.trailingAnchor.constraint(equalTo: cartItemDeleteButton.leadingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: textFieldSuperview.bottomAnchor, constant: -8),
            containerView.widthAnchor.constraint(equalToConstant: 90),
            containerView.heightAnchor.constraint(equalToConstant: 28),
            
            // Minus button
            minusButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            minusButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            minusButton.widthAnchor.constraint(equalToConstant: 24),
            minusButton.heightAnchor.constraint(equalToConstant: 24),
            
            // TextField
            textField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            textField.widthAnchor.constraint(equalToConstant: 30),
            
            // Plus button
            plusButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            plusButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 24),
            plusButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with item: CartItemModel) {
        currentItem = item
        currentQuantity = item.quantity
        
        // Title
        cartItemTitleLabel?.text = item.productName
        
        // Description
        cartItemDescLabel?.text = item.productDescription
        
        // Price - format with VND
        let priceText = item.price.trimmingCharacters(in: .whitespaces)
        cartItemAmountLabel?.text = "\(priceText) VND"
        
        // Selection state
        updateSelectionState(item.isSelected)
        
        // Load image
        if let imageUrl = item.productImageUrl {
            loadImage(from: imageUrl)
        } else {
            cartItemImageView?.image = nil
            cartItemImageView?.backgroundColor = .systemGray5
        }
    }
    
    private func updateSelectionState(_ isSelected: Bool) {
        let bundle = Bundle(for: type(of: self))
        let iconName = isSelected ? "ic_radio_check" : "ic_new_tick_not_select"
        let icon = HelperFunction.getImage(named: iconName, in: bundle)
        onChooseButton.setImage(icon, for: .normal)
    }
    
    private func loadImage(from urlString: String) {
        guard let fullURLString = urlString.fullImageURL(),
              let url = URL(string: fullURLString) else {
            cartItemImageView?.image = nil
            cartItemImageView?.backgroundColor = .systemGray5
            return
        }
        
        imageCache.loadImage(from: url) { [weak self] image in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.cartItemImageView?.image = image
                if image != nil {
                    self.cartItemImageView?.backgroundColor = nil
                }
            }
        }
    }
    
    @objc private func chooseButtonTapped() {
        onToggleSelection?()
    }
    
    @objc private func minusTapped() {
        guard currentQuantity > 1 else { return }
        currentQuantity -= 1
        onQuantityChanged?(currentQuantity)
    }
    
    @objc private func plusTapped() {
        currentQuantity += 1
        onQuantityChanged?(currentQuantity)
    }
    
    @objc private func deleteButtonTapped() {
        showDeleteConfirmation()
    }
    
    private func showDeleteConfirmation() {
        // Find the view controller to present alert
        guard let viewController = findViewController() else {
            // Fallback: call onDelete directly if can't find view controller
            onDelete?()
            return
        }
        
        let alert = UIAlertController(
            title: nil,
            message: "Are you sure to delete this item?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
            self?.onDelete?()
        })
        
        viewController.present(alert, animated: true)
    }
    
    // Helper method to find the view controller that contains this cell
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if let viewController = responder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

// MARK: - UITextFieldDelegate

extension CartItemCell: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == cartItemTextField {
            if let text = textField.text, let value = Int(text), value > 0 {
                currentQuantity = value
                onQuantityChanged?(currentQuantity)
            } else {
                textField.text = "\(currentQuantity)"
            }
        }
    }
}
