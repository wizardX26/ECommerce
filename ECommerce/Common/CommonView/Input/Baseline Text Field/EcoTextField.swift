//
//  EcoTextField.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

// MARK: - EcoTextFieldType

public enum EcoTextFieldType {
    case baseline
    case secure
}

// MARK: - EcoTextFieldDelegate

public protocol EcoTextFieldDelegate: AnyObject {
    func textFieldDidChange(_ textField: EcoTextField)
    func textFieldDidBeginEditing(_ textField: EcoTextField)
    func textFieldDidEndEditing(_ textField: EcoTextField)
    func textFieldShouldReturn(_ textField: EcoTextField) -> Bool
}

public extension EcoTextFieldDelegate {
    func textFieldDidChange(_ textField: EcoTextField) {}
    func textFieldDidBeginEditing(_ textField: EcoTextField) {}
    func textFieldDidEndEditing(_ textField: EcoTextField) {}
    func textFieldShouldReturn(_ textField: EcoTextField) -> Bool { return true }
}

// MARK: - EcoTextField

@IBDesignable
open class EcoTextField: UITextField {
    
    // MARK: - Properties
    
    public var type: EcoTextFieldType = .baseline {
        didSet {
            updateTextFieldType()
        }
    }
    
    public weak var ecoDelegate: EcoTextFieldDelegate?
    
    // MARK: - UI Components
    
    private let leftIconImageView = UIImageView()
    private let clearButton = UIButton(type: .system)
    private let secureToggleButton = UIButton(type: .system)
    private let helperLabel = UILabel()
    private let errorIconImageView = UIImageView()
    
    // MARK: - Styling Properties
    
    @IBInspectable public var leftIcon: UIImage? {
        didSet {
            updateLeftIcon()
        }
    }
    
    @IBInspectable public var leftIconName: String? {
        didSet {
            if let iconName = leftIconName {
                leftIcon = UIImage(systemName: iconName)
            }
        }
    }
    
    @IBInspectable public var leftIconTintColor: UIColor = Colors.tokenDark60 {
        didSet {
            leftIconImageView.tintColor = leftIconTintColor
        }
    }
    
    @IBInspectable public var showsClearButton: Bool = true {
        didSet {
            updateClearButton()
        }
    }
    
    @IBInspectable public var helperText: String = "" {
        didSet {
            updateHelperText()
        }
    }
    
    @IBInspectable public var errorMessage: String = "" {
        didSet {
            updateErrorState()
        }
    }
    
    @IBInspectable public var isError: Bool = false {
        didSet {
            updateErrorState()
        }
    }
    
    @IBInspectable public var borderColor: UIColor = Colors.tokenDark10 {
        didSet {
            updateBorder()
        }
    }
    
    @IBInspectable public var errorBorderColor: UIColor = Colors.tokenRed100 {
        didSet {
            updateBorder()
        }
    }
    
    @IBInspectable public var selectedBorderColor: UIColor = Colors.tokenRainbowBlueEnd {
        didSet {
            updateBorder()
        }
    }
    
    @IBInspectable public var backgroundColorColor: UIColor = Colors.tokenDark02 {
        didSet {
            backgroundColor = backgroundColorColor
        }
    }
    
    @IBInspectable public var cornerRadius: CGFloat = 12 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable public var borderWidth: CGFloat = 1 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    // MARK: - Private Properties
    
    private var leftPaddingView: UIView?
    private var rightStackView: UIStackView?
    private var helperTextHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextField()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextField()
    }
    
    // MARK: - Setup
    
    private func setupTextField() {
        // Basic setup
        borderStyle = .none
        backgroundColor = backgroundColorColor
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        
        // Text styling - ensure text is visible
        textColor = Colors.tokenDark100
        font = UIFont.systemFont(ofSize: 16, weight: .regular)
        tintColor = Colors.tokenRainbowBlueEnd // Cursor color
        
        // Ensure text is always visible
        clearsOnBeginEditing = false
        clearsOnInsertion = false
        
        // Force text color to be visible
        setNeedsDisplay()
        
        // Placeholder styling
        if let placeholder = placeholder {
            attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [NSAttributedString.Key.foregroundColor: Colors.tokenDark40]
            )
        }
        
        // Setup left icon
        setupLeftIcon()
        
        // Setup right buttons
        setupRightButtons()
        
        // Setup helper label
        setupHelperLabel()
        
        // Add targets
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        
        // Delegate
        delegate = self
    }
    
    private func setupLeftIcon() {
        leftIconImageView.contentMode = .scaleAspectFit
        leftIconImageView.tintColor = leftIconTintColor
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 56))
        leftIconImageView.frame = CGRect(x: 15, y: 0, width: 20, height: 20)
        leftIconImageView.center.y = paddingView.center.y
        paddingView.addSubview(leftIconImageView)
        
        leftPaddingView = paddingView
        leftView = paddingView
        leftViewMode = .always
        
        // Ensure text field has proper text rect
        updateLeftIcon()
    }
    
    public override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        // Return leftView rect - UITextField sẽ tự động sử dụng
        if let leftView = leftView, leftViewMode != .never {
            return CGRect(x: 0, y: 0, width: leftView.frame.width, height: bounds.height)
        }
        return .zero
    }
    
    public override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        // Return rightView rect - UITextField sẽ tự động sử dụng
        if let rightView = rightView, rightViewMode != .never {
            return CGRect(x: bounds.width - rightView.frame.width, y: 0, width: rightView.frame.width, height: bounds.height)
        }
        return .zero
    }
    
    public override func textRect(forBounds bounds: CGRect) -> CGRect {
        // Tính toán rect để text bắt đầu từ bên phải icon đầu tiên 6pt
        // và kết thúc ở bên trái icon thứ 2 (rightView) 6pt (hoặc 12pt nếu là password field)
        var rect = bounds
        
        // Padding bên trái: 4pt
        let leftPadding: CGFloat = 4
        
        // Padding bên phải: 16pt cho password field, 4pt cho các field khác
        let rightPadding: CGFloat = (type == .secure) ? 24 : 4
        
        // Điều chỉnh cho leftView - cách 6pt từ icon
        if let leftView = leftView, leftViewMode != .never {
            let leftViewWidth = leftView.frame.width
            // Text bắt đầu từ sau leftView + 6pt
            rect.origin.x = leftViewWidth + leftPadding
            rect.size.width = bounds.width - leftViewWidth - leftPadding
        } else {
            // Không có leftView, padding từ cạnh trái 6pt
            rect.origin.x = leftPadding
            rect.size.width = bounds.width - leftPadding * 2
        }
        
        // Điều chỉnh cho rightView - cách 6pt hoặc 12pt từ icon (tùy loại field)
        if let rightView = rightView, rightViewMode != .never {
            let rightViewWidth = rightView.frame.width
            // Text kết thúc trước rightView - rightPadding
            rect.size.width = rect.size.width - rightViewWidth - rightPadding
        } else {
            // Không có rightView, padding từ cạnh phải
            rect.size.width = rect.size.width - rightPadding
        }
        
        // Đảm bảo width không âm và origin không vượt quá bounds
        rect.size.width = max(0, rect.size.width)
        rect.origin.x = min(rect.origin.x, bounds.width - rect.size.width)
        
        // Vertical: chiếm toàn bộ chiều cao
        rect.origin.y = 0
        rect.size.height = bounds.height
        
        return rect
    }
    
    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
        // Tính toán rect để text bắt đầu từ bên phải icon đầu tiên 6pt
        // và kết thúc ở bên trái icon thứ 2 (rightView) 6pt (hoặc 12pt nếu là password field)
        var rect = bounds
        
        // Padding bên trái: 4pt
        let leftPadding: CGFloat = 0
        
        // Padding bên phải: 20pt cho password field, 4pt cho các field khác
        let rightPadding: CGFloat = (type == .secure) ? 20 : 0
        
        // Điều chỉnh cho leftView - cách 6pt từ icon
        if let leftView = leftView, leftViewMode != .never {
            let leftViewWidth = leftView.frame.width
            // Text bắt đầu từ sau leftView + 6pt
            rect.origin.x = leftViewWidth + leftPadding
            rect.size.width = bounds.width - leftViewWidth - leftPadding
        } else {
            // Không có leftView, padding từ cạnh trái 6pt
            rect.origin.x = leftPadding
            rect.size.width = bounds.width - leftPadding * 2
        }
        
        // Điều chỉnh cho rightView - cách 6pt hoặc 12pt từ icon (tùy loại field)
        if let rightView = rightView, rightViewMode != .never {
            let rightViewWidth = rightView.frame.width
            // Text kết thúc trước rightView - rightPadding
            rect.size.width = rect.size.width - rightViewWidth - rightPadding
        } else {
            // Không có rightView, padding từ cạnh phải
            rect.size.width = rect.size.width - rightPadding
        }
        
        // Đảm bảo width không âm và origin không vượt quá bounds
        rect.size.width = max(0, rect.size.width)
        rect.origin.x = min(rect.origin.x, bounds.width - rect.size.width)
        
        // Vertical: chiếm toàn bộ chiều cao
        rect.origin.y = 0
        rect.size.height = bounds.height
        
        return rect
    }
    
    public override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        // Tính toán rect để placeholder bắt đầu từ bên phải icon đầu tiên 6pt
        // và kết thúc ở bên trái icon thứ 2 (rightView) 6pt (hoặc 12pt nếu là password field)
        var rect = bounds
        
        // Padding bên trái: 6pt
        let leftPadding: CGFloat = 6
        
        // Padding bên phải: 12pt cho password field, 6pt cho các field khác
        let rightPadding: CGFloat = (type == .secure) ? 12 : 6
        
        // Điều chỉnh cho leftView - cách 6pt từ icon
        if let leftView = leftView, leftViewMode != .never {
            let leftViewWidth = leftView.frame.width
            // Placeholder bắt đầu từ sau leftView + 6pt
            rect.origin.x = leftViewWidth + leftPadding
            rect.size.width = bounds.width - leftViewWidth - leftPadding
        } else {
            // Không có leftView, padding từ cạnh trái 6pt
            rect.origin.x = leftPadding
            rect.size.width = bounds.width - leftPadding * 2
        }
        
        // Điều chỉnh cho rightView - cách 6pt hoặc 12pt từ icon (tùy loại field)
        if let rightView = rightView, rightViewMode != .never {
            let rightViewWidth = rightView.frame.width
            // Placeholder kết thúc trước rightView - rightPadding
            rect.size.width = rect.size.width - rightViewWidth - rightPadding
        } else {
            // Không có rightView, padding từ cạnh phải
            rect.size.width = rect.size.width - rightPadding
        }
        
        // Đảm bảo width không âm và origin không vượt quá bounds
        rect.size.width = max(0, rect.size.width)
        rect.origin.x = min(rect.origin.x, bounds.width - rect.size.width)
        
        // Vertical: chiếm toàn bộ chiều cao
        rect.origin.y = 0
        rect.size.height = bounds.height
        
        return rect
    }
    
    private func setupRightButtons() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        
        // Clear button
        clearButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.tintColor = Colors.tokenDark40
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        clearButton.isHidden = true
        
        // Secure toggle button (for password fields)
        secureToggleButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        secureToggleButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        secureToggleButton.tintColor = Colors.tokenDark60
        secureToggleButton.addTarget(self, action: #selector(toggleSecureEntry), for: .touchUpInside)
        secureToggleButton.isHidden = true
        
        stackView.addArrangedSubview(clearButton)
        stackView.addArrangedSubview(secureToggleButton)
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 56))
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        rightStackView = stackView
        rightView = containerView
        rightViewMode = .whileEditing
        
        updateRightButtons()
    }
    
    private func setupHelperLabel() {
        helperLabel.translatesAutoresizingMaskIntoConstraints = false
        helperLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        helperLabel.textColor = Colors.tokenDark60
        helperLabel.numberOfLines = 0
        helperLabel.isHidden = true
        
        // Add to superview if available
        if let superview = superview {
            superview.addSubview(helperLabel)
            NSLayoutConstraint.activate([
                helperLabel.topAnchor.constraint(equalTo: bottomAnchor, constant: 4),
                helperLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
                helperLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        }
    }
    
    // MARK: - Updates
    
    private func updateTextFieldType() {
        switch type {
        case .baseline:
            isSecureTextEntry = false
            secureToggleButton.isHidden = true
        case .secure:
            secureToggleButton.isHidden = false
            isSecureTextEntry = true
        }
        updateRightButtons()
    }
    
    private func updateLeftIcon() {
        leftIconImageView.image = leftIcon
        leftIconImageView.isHidden = (leftIcon == nil)
    }
    
    private func updateRightButtons() {
        clearButton.isHidden = !showsClearButton || (text?.isEmpty ?? true) || !isFirstResponder
        
        if type == .secure {
            secureToggleButton.isHidden = false
            let imageName = isSecureTextEntry ? "eye.slash" : "eye"
            secureToggleButton.setImage(UIImage(systemName: imageName), for: .normal)
        } else {
            secureToggleButton.isHidden = true
        }
    }
    
    private func updateClearButton() {
        updateRightButtons()
    }
    
    private func updateHelperText() {
        guard !helperText.isEmpty || !errorMessage.isEmpty else {
            helperLabel.isHidden = true
            return
        }
        
        helperLabel.isHidden = false
        helperLabel.text = isError ? errorMessage : helperText
        helperLabel.textColor = isError ? Colors.tokenRed100 : Colors.tokenDark60
    }
    
    private func updateErrorState() {
        updateBorder()
        updateHelperText()
    }
    
    private func updateBorder() {
        if isError {
            layer.borderColor = errorBorderColor.cgColor
        } else if isFirstResponder {
            layer.borderColor = selectedBorderColor.cgColor
        } else {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    // MARK: - Actions
    
    @objc private func textDidChange() {
        updateRightButtons()
        ecoDelegate?.textFieldDidChange(self)
    }
    
    @objc private func clearButtonTapped() {
        text = ""
        updateRightButtons()
        ecoDelegate?.textFieldDidChange(self)
    }
    
    @objc private func toggleSecureEntry() {
        isSecureTextEntry.toggle()
        updateRightButtons()
    }
    
    // MARK: - Overrides
    
    public override var placeholder: String? {
        didSet {
            if let placeholder = placeholder {
                attributedPlaceholder = NSAttributedString(
                    string: placeholder,
                    attributes: [NSAttributedString.Key.foregroundColor: Colors.tokenDark40]
                )
            }
        }
    }
    
    public override var isSecureTextEntry: Bool {
        didSet {
            super.isSecureTextEntry = isSecureTextEntry
            updateRightButtons()
        }
    }
    
    public override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        updateBorder()
        updateRightButtons()
        return result
    }
    
    public override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        updateBorder()
        updateRightButtons()
        return result
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update helper label position if superview exists
        if helperLabel.superview != nil {
            helperLabel.removeFromSuperview()
        }
        if let superview = superview {
            superview.addSubview(helperLabel)
            NSLayoutConstraint.activate([
                helperLabel.topAnchor.constraint(equalTo: bottomAnchor, constant: 4),
                helperLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
                helperLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        }
    }
    
    // MARK: - Public Methods
    
    public func setError(_ message: String) {
        errorMessage = message
        isError = true
    }
    
    public func clearError() {
        errorMessage = ""
        isError = false
    }
    
    public func setLeftIcon(_ icon: UIImage?, tintColor: UIColor? = nil) {
        leftIcon = icon
        if let tintColor = tintColor {
            leftIconTintColor = tintColor
        }
    }
    
    public func setLeftIcon(_ iconName: String, tintColor: UIColor? = nil) {
        leftIconName = iconName
        if let tintColor = tintColor {
            leftIconTintColor = tintColor
        }
    }
}

// MARK: - UITextFieldDelegate

extension EcoTextField: UITextFieldDelegate {
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Cho phép tất cả ký tự bao gồm dấu cách
        // Mặc định return true để cho phép tất cả input
        return true
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        updateBorder()
        updateRightButtons()
        ecoDelegate?.textFieldDidBeginEditing(self)
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        updateBorder()
        updateRightButtons()
        ecoDelegate?.textFieldDidEndEditing(self)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return ecoDelegate?.textFieldShouldReturn(self) ?? true
    }
}
