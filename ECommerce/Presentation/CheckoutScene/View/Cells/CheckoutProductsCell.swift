//
//  CheckoutProductsCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 15/1/26.
//

import UIKit

final class CheckoutProductsCell: UICollectionViewCell {
    
    private let shippingFeeLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontRegular14
        label.textColor = Colors.tokenDark60
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let itemsCountLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontRegular14
        label.textColor = Colors.tokenDark100
        label.text = "22 items in total"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let productsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let addNoteLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontRegular14
        label.textColor = Colors.tokenRainbowBlueEnd
        label.text = "Add note to seller"
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        let attributedString = NSMutableAttributedString(string: "Add note to seller")
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: "Add note to seller".count))
        label.attributedText = attributedString
        return label
    }()
    
    private var items: [CheckoutCartItem] = []
    private var onQuantityChanged: ((Int, Int) -> Void)?
    private var onTapAddNote: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        contentView.addSubview(shippingFeeLabel)
        contentView.addSubview(itemsCountLabel)
        contentView.addSubview(productsCollectionView)
        contentView.addSubview(addNoteLabel)
        
        productsCollectionView.delegate = self
        productsCollectionView.dataSource = self
        productsCollectionView.register(ProductItemCheckoutCell.self, forCellWithReuseIdentifier: "ProductItemCheckoutCell")
        
        NSLayoutConstraint.activate([
            shippingFeeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            shippingFeeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            itemsCountLabel.topAnchor.constraint(equalTo: shippingFeeLabel.bottomAnchor, constant: 2),
            itemsCountLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            productsCollectionView.topAnchor.constraint(equalTo: itemsCountLabel.bottomAnchor, constant: 3),
            productsCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            productsCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            productsCollectionView.heightAnchor.constraint(equalToConstant: 150),
            
            addNoteLabel.topAnchor.constraint(equalTo: productsCollectionView.bottomAnchor, constant: 8),
            addNoteLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            addNoteLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        let noteTap = UITapGestureRecognizer(target: self, action: #selector(addNoteTapped))
        addNoteLabel.addGestureRecognizer(noteTap)
    }
    
    func configure(
        items: [CheckoutCartItem],
        note: String?,
        shippingFeePerItem: String?,
        onQuantityChanged: @escaping (Int, Int) -> Void,
        onTapAddNote: @escaping () -> Void
    ) {
        self.items = items
        self.onQuantityChanged = onQuantityChanged
        self.onTapAddNote = onTapAddNote
        
        let totalItems = items.reduce(0) { $0 + $1.quantity }
        itemsCountLabel.text = "\(totalItems) items in total"
        
        // Tính shipping fee: số lượng sản phẩm * shipping_fee từ address
        if let shippingFeeString = shippingFeePerItem,
           !shippingFeeString.isEmpty,
           let shippingFeePerItemValue = Double(shippingFeeString),
           shippingFeePerItemValue > 0 {
            let totalShippingFee = shippingFeePerItemValue * Double(totalItems)
            let shippingFormatted = totalShippingFee.formattedWithSeparatorWithoutTrailingZeros
            shippingFeeLabel.text = "\(shippingFormatted) vnd"
        } else {
            shippingFeeLabel.text = "Calculate by address"
        }
        
        productsCollectionView.reloadData()
    }
    
    @objc private func addNoteTapped() {
        onTapAddNote?()
    }
}

extension CheckoutProductsCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductItemCheckoutCell", for: indexPath) as! ProductItemCheckoutCell
        cell.configure(item: items[indexPath.item], onQuantityChanged: { [weak self] productId, quantity in
            self?.onQuantityChanged?(productId, quantity)
        })
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 120, height: 172)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}

// MARK: - ProductItemCell

private class ProductItemCheckoutCell: UICollectionViewCell {
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit // Đổi sang fit để ảnh vừa vặn trong khung
        iv.clipsToBounds = true // Clip để image không tràn
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .systemGray5
        iv.translatesAutoresizingMaskIntoConstraints = false
        
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontRegular12
        label.textColor = Colors.tokenDark100
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontBold14
        label.textColor = Colors.tokenDark100
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let quantityStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.distribution = .fill
        stack.backgroundColor = UIColor.systemGray5 // Màu xám hơn nền trắng
        stack.layer.cornerRadius = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let minusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("-", for: .normal)
        button.titleLabel?.font = Typography.fontBold16
        button.setTitleColor(Colors.tokenDark100, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontRegular14
        label.textColor = Colors.tokenDark100
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = Typography.fontBold16
        button.setTitleColor(Colors.tokenDark100, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var item: CheckoutCartItem?
    private var onQuantityChanged: ((Int, Int) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(quantityStack)
        
        quantityStack.addArrangedSubview(minusButton)
        quantityStack.addArrangedSubview(quantityLabel)
        quantityStack.addArrangedSubview(plusButton)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Căn chỉnh nameLabel center với imageView
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            nameLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            nameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            
            // Căn chỉnh priceLabel center với imageView
            priceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            priceLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            priceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            priceLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            
            // Căn chỉnh quantityStack center với imageView
            quantityStack.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 6),
            quantityStack.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            quantityStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            quantityStack.widthAnchor.constraint(equalToConstant: 90),
            quantityStack.heightAnchor.constraint(equalToConstant: 32),
            
            minusButton.widthAnchor.constraint(equalToConstant: 30),
            quantityLabel.widthAnchor.constraint(equalToConstant: 30),
            plusButton.widthAnchor.constraint(equalToConstant: 30)
        ])
        
        minusButton.addTarget(self, action: #selector(minusTapped), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
    }
    
    func configure(item: CheckoutCartItem, onQuantityChanged: @escaping (Int, Int) -> Void) {
        self.item = item
        self.onQuantityChanged = onQuantityChanged
        
        nameLabel.text = item.productName
        priceLabel.text = "\(item.price) vnd"
        quantityLabel.text = "\(item.quantity)"
        
        // Load product image
        if let imageUrl = item.productImageUrl {
            loadImage(from: imageUrl)
        } else {
            imageView.image = nil
            imageView.backgroundColor = .systemGray5
        }
    }
    
    private func loadImage(from urlString: String) {
        // Sử dụng helper function để ghép URL
        guard let fullURLString = urlString.fullImageURL(),
              let url = URL(string: fullURLString) else {
            imageView.image = nil
            imageView.backgroundColor = .systemGray5
            return
        }
        
        // Load image using ImageCache service
        let imageCache = DefaultImageCacheService.shared
        imageCache.loadImage(from: url) { [weak self] image in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.imageView.image = image
                if image != nil {
                    self.imageView.backgroundColor = nil
                }
            }
        }
    }
    
    @objc private func minusTapped() {
        guard let item = item, item.quantity > 1 else { return }
        onQuantityChanged?(item.productId, item.quantity - 1)
    }
    
    @objc private func plusTapped() {
        guard let item = item else { return }
        onQuantityChanged?(item.productId, item.quantity + 1)
    }
}
