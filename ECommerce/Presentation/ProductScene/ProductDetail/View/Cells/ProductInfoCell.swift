//
//  ProductInfoCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit

final class ProductInfoCell: UICollectionViewCell {
    
    static let reuseIdentifierProductInfo = String(describing: ProductInfoCell.self)
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.isScrollEnabled = false // Tắt scroll để chỉ có collectionView scroll
        return sv
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    // Product Information Label
    private let productInfoLabel: UILabel = {
        let label = UILabel()
        label.text = "Product Information"
        label.font = .boldSystemFont(ofSize: 22) // Increased from 20 to 22
        label.textColor = .black
        return label
    }()
    
    // Price View
    private let priceView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 24)
        label.textColor = .black
        return label
    }()
    
    // Quantity Controls - giống OrderQuantityCell
    private let quantityContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.tokenDark02
        view.layer.cornerRadius = BorderRadius.tokenBorderRadius12
        view.layer.borderWidth = Sizing.tokenSizing01
        view.layer.borderColor = Colors.tokenDark10.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let quantityMinusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("-", for: .normal)
        button.titleLabel?.font = Typography.fontBold18
        button.setTitleColor(Colors.tokenDark100, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let quantityTextField: UITextField = {
        let textField = UITextField()
        textField.text = "1"
        textField.textAlignment = .center
        textField.font = Typography.fontMedium14
        textField.textColor = Colors.tokenDark100
        textField.keyboardType = .numberPad
        textField.borderStyle = .none
        textField.backgroundColor = Colors.tokenWhite
        textField.layer.cornerRadius = BorderRadius.tokenBorderRadius08
        textField.layer.masksToBounds = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let quantityPlusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = Typography.fontBold18
        button.setTitleColor(Colors.tokenDark100, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Callback
    var onQuantityChanged: ((Int) -> Void)?
    
    private var currentQuantity: Int = 1 {
        didSet {
            quantityTextField.text = "\(currentQuantity)"
            onQuantityChanged?(currentQuantity)
        }
    }
    
    // Description
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .black
        label.numberOfLines = 5
        return label
    }()
    
    // Sold info
    private let soldInfoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private let soldCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    private let separatorLabel: UILabel = {
        let label = UILabel()
        label.text = "|"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    private let soldByLabel: UILabel = {
        let label = UILabel()
        label.text = "sold by"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    private let sellerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = .systemGray4
        iv.widthAnchor.constraint(equalToConstant: 24).isActive = true
        iv.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return iv
    }()
    
    // Rating
    private let ratingStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    
    private let starsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let ratingValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    // Guaranteed Cell
    private let guaranteedCell: ProductGuaranteedCell = {
        let cell = ProductGuaranteedCell()
        return cell
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupQuantityControls() {
        priceView.addSubview(quantityContainerView)
        quantityContainerView.addSubview(quantityMinusButton)
        quantityContainerView.addSubview(quantityTextField)
        quantityContainerView.addSubview(quantityPlusButton)
        
        quantityMinusButton.addTarget(self, action: #selector(quantityMinusTapped), for: .touchUpInside)
        quantityPlusButton.addTarget(self, action: #selector(quantityPlusTapped), for: .touchUpInside)
        quantityTextField.delegate = self
        
        // Constraints giống OrderQuantityCell
        NSLayoutConstraint.activate([
            quantityContainerView.trailingAnchor.constraint(equalTo: priceView.trailingAnchor, constant: -Spacing.tokenSpacing16),
            quantityContainerView.centerYAnchor.constraint(equalTo: priceView.centerYAnchor),
            quantityContainerView.heightAnchor.constraint(equalToConstant: 40),
            quantityContainerView.widthAnchor.constraint(equalToConstant: 120),
            
            quantityMinusButton.leadingAnchor.constraint(equalTo: quantityContainerView.leadingAnchor, constant: Spacing.tokenSpacing08),
            quantityMinusButton.centerYAnchor.constraint(equalTo: quantityContainerView.centerYAnchor),
            quantityMinusButton.widthAnchor.constraint(equalToConstant: 24),
            quantityMinusButton.heightAnchor.constraint(equalToConstant: 24),
            
            quantityTextField.centerXAnchor.constraint(equalTo: quantityContainerView.centerXAnchor),
            quantityTextField.centerYAnchor.constraint(equalTo: quantityContainerView.centerYAnchor),
            quantityTextField.widthAnchor.constraint(equalToConstant: 40),
            
            quantityPlusButton.trailingAnchor.constraint(equalTo: quantityContainerView.trailingAnchor, constant: -Spacing.tokenSpacing08),
            quantityPlusButton.centerYAnchor.constraint(equalTo: quantityContainerView.centerYAnchor),
            quantityPlusButton.widthAnchor.constraint(equalToConstant: 24),
            quantityPlusButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    @objc private func quantityMinusTapped() {
        if currentQuantity > 1 {
            currentQuantity -= 1
        }
    }
    
    @objc private func quantityPlusTapped() {
        currentQuantity += 1
    }
    
    private func setupUI() {
        contentView.addSubview(scrollView)
        scrollView.addSubview(containerView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Price View
        priceView.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Quantity Controls
        setupQuantityControls()
        
        // Sold Info Stack
        soldInfoStackView.addArrangedSubview(soldCountLabel)
        soldInfoStackView.addArrangedSubview(separatorLabel)
        soldInfoStackView.addArrangedSubview(soldByLabel)
        soldInfoStackView.addArrangedSubview(sellerImageView)
        
        // Rating Stack
        ratingStackView.addArrangedSubview(starsLabel)
        ratingStackView.addArrangedSubview(ratingValueLabel)
        
        // Add all to container view
        containerView.addSubview(productInfoLabel)
        containerView.addSubview(priceView)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(soldInfoStackView)
        containerView.addSubview(ratingStackView)
        containerView.addSubview(guaranteedCell)
        
        productInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        priceView.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        soldInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        ratingStackView.translatesAutoresizingMaskIntoConstraints = false
        guaranteedCell.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Container View
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Product Information Label - cách top 12pt, leading 8pt (giống priceView)
            productInfoLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            productInfoLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            
            // Price View - center horizontal với cell 1, leading 8pt, height 96pt, cách productInfoLabel 12pt
            priceView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            priceView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            priceView.topAnchor.constraint(equalTo: productInfoLabel.bottomAnchor, constant: 12),
            priceView.heightAnchor.constraint(equalToConstant: 96),
            
            // Price Label - leading và center vertical
            priceLabel.leadingAnchor.constraint(equalTo: priceView.leadingAnchor, constant: 16),
            priceLabel.centerYAnchor.constraint(equalTo: priceView.centerYAnchor),
            
            // Quantity Controls constraints are set in setupQuantityControls()
            
            // Description - leading, cách bottom view giá 16pt
            descriptionLabel.topAnchor.constraint(equalTo: priceView.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Sold Info Stack
            soldInfoStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            soldInfoStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            // Rating Stack
            ratingStackView.topAnchor.constraint(equalTo: soldInfoStackView.bottomAnchor, constant: 16),
            ratingStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            // Guaranteed Cell
            guaranteedCell.topAnchor.constraint(equalTo: ratingStackView.bottomAnchor, constant: 16),
            guaranteedCell.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            guaranteedCell.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            // Tăng padding bottom để tạo khoảng trống phía dưới (1/3 chiều cao màn hình)
            // Khoảng trống này sẽ được tích hợp vào chiều cao của cell 1
            guaranteedCell.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -(UIScreen.main.bounds.height / 3))
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with product: ProductDetailModel) {
        // Price
        priceLabel.text = "\(product.price) vnd"
        
        // Description
        descriptionLabel.text = product.description
        
        // Sold info
        if let soldCount = product.soldCount {
            soldCountLabel.text = "\(soldCount)+ sold"
        } else {
            soldCountLabel.text = "100+ sold"
        }
        
        // Seller image (placeholder for now)
        sellerImageView.image = nil
        
        // Rating
        if let stars = product.stars {
            starsLabel.text = String(repeating: "⭐", count: stars)
            ratingValueLabel.text = "\(stars)"
        } else {
            starsLabel.text = ""
            ratingValueLabel.text = ""
        }
        
        // Guaranteed cell (no configuration needed, it's static)
    }
}

// MARK: - UITextFieldDelegate

extension ProductInfoCell: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == quantityTextField {
            if let text = textField.text, let value = Int(text), value > 0 {
                currentQuantity = value
            } else {
                quantityTextField.text = "\(currentQuantity)"
            }
        }
    }
}
