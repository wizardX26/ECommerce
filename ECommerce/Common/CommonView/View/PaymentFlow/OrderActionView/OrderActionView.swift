//
//  OrderActionView.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit

// MARK: - OrderActionViewDelegate

public protocol OrderActionViewDelegate: AnyObject {
    /// Called when the action button is tapped
    func orderActionViewDidTapAction(_ view: OrderActionView)
    
    /// Called when the left item (icon/label) is tapped (optional)
    func orderActionViewDidTapLeftItem(_ view: OrderActionView)
    
    /// Called when the top right label is tapped (optional)
    func orderActionViewDidTapTopRightLabel(_ view: OrderActionView)
}

public extension OrderActionViewDelegate {
    func orderActionViewDidTapLeftItem(_ view: OrderActionView) {}
    func orderActionViewDidTapTopRightLabel(_ view: OrderActionView) {}
}

// MARK: - OrderActionView

/// A reusable UIView component for order/checkout flow actions
/// Layout:
/// [Label 1                                             Label 2]
/// [Label3/icon               dynamicWidthButton]
public class OrderActionView: UIView {
    
    // MARK: - Public Properties
    
    public weak var delegate: OrderActionViewDelegate?
    
    /// Top left label text (DEPRECATED - Always hidden in Checkout)
    public var topLeftLabelText: String? {
        get { topLeftLabel.text }
        set { 
            topLeftLabel.text = newValue
            topLeftLabel.isHidden = true // Always hidden
        }
    }
    
    /// Top right label text (DEPRECATED - Always hidden in Checkout)
    public var topRightLabelText: String? {
        get { topRightLabel.text }
        set { 
            topRightLabel.text = newValue
            topRightLabel.isHidden = true // Always hidden
        }
    }
    
    /// Bottom left item - can be icon or label
    public enum LeftItemType {
        case icon(UIImage?)
        case label(String)
        case none
    }
    
    public var leftItemType: LeftItemType = .none {
        didSet {
            updateLeftItem()
        }
    }
    
    /// Action button title
    public var buttonTitle: String? {
        get { actionButton.title(for: .normal) }
        set { actionButton.setTitle(newValue, for: .normal) }
    }
    
    /// Action button width (nil = auto width based on content)
    public var buttonWidth: CGFloat? {
        didSet {
            updateButtonWidthConstraint()
        }
    }
    
    /// Minimum button width
    public var buttonMinWidth: CGFloat = 100 {
        didSet {
            actionButtonMinWidthConstraint?.constant = buttonMinWidth
        }
    }
    
    /// Maximum button width
    public var buttonMaxWidth: CGFloat? {
        didSet {
            updateButtonWidthConstraint()
        }
    }
    
    /// Button loading state
    public var isLoading: Bool = false {
        didSet {
            actionButton.setLoading(isLoading)
        }
    }
    
    /// Button enabled state
    public var isButtonEnabled: Bool = true {
        didSet {
            actionButton.isEnabled = isButtonEnabled
            actionButton.buttonState = isButtonEnabled ? .normal : .disabled
        }
    }
    
    /// Button corner radius
    public var buttonCornerRadius: CGFloat = BorderRadius.tokenBorderRadius12 {
        didSet {
            actionButton.cornerRadius = buttonCornerRadius
        }
    }
    
    // MARK: - UI Components
    
    private let containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.tokenSpacing12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Top row: Labels
    private let topRowStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let topLeftLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontRegular14
        label.textColor = Colors.tokenDark60
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let topRightLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontRegular14
        label.textColor = Colors.tokenDark100
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Bottom row: Left item + Button
    private let bottomRowStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fill // Icon sẽ có fixed width, button sẽ expand
        stack.alignment = .center
        stack.spacing = Spacing.tokenSpacing12 // Spacing 12pt giữa icon và button
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let leftItemContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let leftItemIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = Colors.tokenDark100
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let leftItemLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontRegular14
        label.textColor = Colors.tokenDark100
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let actionButton: EcoButton = {
        let button = EcoButton.authButton(title: "Action")
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Constraints
    
    private var actionButtonWidthConstraint: NSLayoutConstraint?
    private var actionButtonMinWidthConstraint: NSLayoutConstraint?
    private var actionButtonMaxWidthConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        backgroundColor = Colors.tokenWhite
        
        // Setup shadow at top edge to separate from parent view
        layer.shadowColor = Colors.tokenBlack.cgColor
        layer.shadowOpacity = Float(Opacity.tokenOpacity08)
        layer.shadowOffset = CGSize(width: 0, height: -Sizing.tokenSizing04)
        layer.shadowRadius = 8
        layer.masksToBounds = false
        
        // Add container stack view
        addSubview(containerStackView)
        
        // Setup top row (hidden by default for Checkout)
        topRowStackView.addArrangedSubview(topLeftLabel)
        topRowStackView.addArrangedSubview(topRightLabel)
        topRowStackView.isHidden = true // Hide top row for Checkout
        containerStackView.addArrangedSubview(topRowStackView)
        
        // Setup bottom row
        leftItemContainer.addSubview(leftItemIconView)
        leftItemContainer.addSubview(leftItemLabel)
        bottomRowStackView.addArrangedSubview(leftItemContainer)
        bottomRowStackView.addArrangedSubview(actionButton)
        containerStackView.addArrangedSubview(bottomRowStackView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Container stack view - padding 12pt from leading and trailing
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.tokenSpacing12),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.tokenSpacing12),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.tokenSpacing12),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.tokenSpacing12),
            
            // Top row labels
            topLeftLabel.heightAnchor.constraint(equalToConstant: 20),
            topRightLabel.heightAnchor.constraint(equalToConstant: 20),
            
            // Left item container - nhỏ, fixed width
            leftItemContainer.heightAnchor.constraint(equalToConstant: 24),
            leftItemContainer.widthAnchor.constraint(equalToConstant: 24),
            
            // Left item icon - nhỏ
            leftItemIconView.centerXAnchor.constraint(equalTo: leftItemContainer.centerXAnchor),
            leftItemIconView.centerYAnchor.constraint(equalTo: leftItemContainer.centerYAnchor),
            leftItemIconView.widthAnchor.constraint(equalToConstant: 20), // Nhỏ hơn
            leftItemIconView.heightAnchor.constraint(equalToConstant: 20),
            
            // Left item label
            leftItemLabel.centerXAnchor.constraint(equalTo: leftItemContainer.centerXAnchor),
            leftItemLabel.centerYAnchor.constraint(equalTo: leftItemContainer.centerYAnchor),
            
            // Action button - chiếm toàn bộ không gian còn lại
            actionButton.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56)
        ])
        
        // Button chiếm toàn bộ không gian còn lại (sau icon và spacing 12pt)
        // bottomRowStackView đã có spacing = 12pt giữa leftItemContainer và actionButton
        // actionButton sẽ tự động expand để fill không gian còn lại
        
        // Setup button width constraints
        setupButtonWidthConstraints()
        
        // Setup button action
        actionButton.ecoDelegate = self
        
        // Setup left item tap gesture
        let leftItemTap = UITapGestureRecognizer(target: self, action: #selector(leftItemTapped))
        leftItemContainer.addGestureRecognizer(leftItemTap)
        leftItemContainer.isUserInteractionEnabled = true
        
        // Setup top right label tap gesture
        topRightLabel.isUserInteractionEnabled = true
        let topRightLabelTap = UITapGestureRecognizer(target: self, action: #selector(topRightLabelTapped))
        topRightLabel.addGestureRecognizer(topRightLabelTap)
        
        // Initial state
        updateLeftItem()
    }
    
    private func setupButtonWidthConstraints() {
        // Minimum width constraint
        actionButtonMinWidthConstraint = actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: buttonMinWidth)
        actionButtonMinWidthConstraint?.isActive = true
        
        // Update width constraint based on buttonWidth property
        updateButtonWidthConstraint()
    }
    
    private func updateButtonWidthConstraint() {
        // Remove existing width constraint
        actionButtonWidthConstraint?.isActive = false
        actionButtonMaxWidthConstraint?.isActive = false
        
        if let width = buttonWidth {
            // Fixed width
            actionButtonWidthConstraint = actionButton.widthAnchor.constraint(equalToConstant: width)
            actionButtonWidthConstraint?.isActive = true
        } else if let maxWidth = buttonMaxWidth {
            // Maximum width only
            actionButtonMaxWidthConstraint = actionButton.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth)
            actionButtonMaxWidthConstraint?.isActive = true
        }
        // Otherwise, button will size based on content (with min width constraint)
    }
    
    private func updateLeftItem() {
        switch leftItemType {
        case .icon(let image):
            leftItemIconView.image = image
            leftItemIconView.isHidden = false
            leftItemLabel.isHidden = true
            leftItemContainer.isHidden = false
            
        case .label(let text):
            leftItemLabel.text = text
            leftItemIconView.isHidden = true
            leftItemLabel.isHidden = false
            leftItemContainer.isHidden = false
            
        case .none:
            leftItemIconView.isHidden = true
            leftItemLabel.isHidden = true
            leftItemContainer.isHidden = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func leftItemTapped() {
        delegate?.orderActionViewDidTapLeftItem(self)
    }
    
    @objc private func topRightLabelTapped() {
        delegate?.orderActionViewDidTapTopRightLabel(self)
    }
    
    // MARK: - Public Methods
    
    /// Configure the view for "Start Order" state
    public func configureForStartOrder(
        topLeftText: String? = nil,
        topRightText: String? = nil,
        buttonTitle: String = "Place Order",
        leftItem: LeftItemType = .none
    ) {
        self.topLeftLabelText = topLeftText
        self.topRightLabelText = topRightText
        self.buttonTitle = buttonTitle
        self.leftItemType = leftItem
        self.isButtonEnabled = true
        self.isLoading = false
    }
    
    /// Configure the view for "Add Address" state
    public func configureForAddAddress(
        topLeftText: String? = "Address required",
        topRightText: String? = nil,
        buttonTitle: String = "Add Address",
        leftItem: LeftItemType = .icon(UIImage(systemName: "location.fill"))
    ) {
        self.topLeftLabelText = topLeftText
        self.topRightLabelText = topRightText
        self.buttonTitle = buttonTitle
        self.leftItemType = leftItem
        self.isButtonEnabled = true
        self.isLoading = false
    }
    
    /// Configure the view for "Checkout" state
    public func configureForCheckout(
        topLeftText: String? = "Total",
        topRightText: String?,
        buttonTitle: String = "Checkout",
        leftItem: LeftItemType = .none
    ) {
        self.topLeftLabelText = topLeftText
        self.topRightLabelText = topRightText
        self.buttonTitle = buttonTitle
        self.leftItemType = leftItem
        self.isButtonEnabled = true
        self.isLoading = false
    }
}

// MARK: - EcoButtonDelegate

extension OrderActionView: EcoButtonDelegate {
    
    public func buttonDidTap(_ button: EcoButton) {
        guard button == actionButton else { return }
        delegate?.orderActionViewDidTapAction(self)
    }
}
