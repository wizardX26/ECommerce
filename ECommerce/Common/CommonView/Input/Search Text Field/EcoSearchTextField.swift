import UIKit

// MARK: - State
public struct EcoSearchState {
    public var text: String
    public var placeholder: String
    public var isEditing: Bool
    public var showsClearButton: Bool
    public var showsCameraButton: Bool
    public var height: CGFloat?
    public var backgroundColor: UIColor?
    public var borderWidth: CGFloat?
    public var borderColor: UIColor?

    public init(
        text: String = "",
        placeholder: String = "Search products",
        isEditing: Bool = false,
        showsClearButton: Bool = true,
        showsCameraButton: Bool = false,
        height: CGFloat? = nil,
        backgroundColor: UIColor? = nil,
        borderWidth: CGFloat? = nil,
        borderColor: UIColor? = nil
    ) {
        self.text = text
        self.placeholder = placeholder
        self.isEditing = isEditing
        self.showsClearButton = showsClearButton
        self.showsCameraButton = showsCameraButton
        self.height = height
        self.backgroundColor = backgroundColor
        self.borderWidth = borderWidth
        self.borderColor = borderColor
    }
}

// MARK: - EcoSearchTextField
public final class EcoSearchTextField: UITextField {

    // MARK: Callbacks (Controller / NavigationBar bind vào)
    public var onTextChange: ((String) -> Void)?
    public var onSubmit: ((String) -> Void)?
    public var onClear: (() -> Void)?
    public var onCameraTap: (() -> Void)?

    // MARK: UI
    private let searchIconView = UIImageView()
    private let clearButton = UIButton(type: .system)
    private let cameraButton = UIButton(type: .system)
    private let rightStack = UIStackView()
    
    // MARK: Camera Button Constraints
    private var cameraButtonWidthConstraint: NSLayoutConstraint?
    private var cameraButtonHeightConstraint: NSLayoutConstraint?

    // MARK: State
    private(set) public var searchState = EcoSearchState()
    
    // MARK: Height Constraint
    /// Height constraint - only used when NOT in navigation style
    private var heightConstraint: NSLayoutConstraint?

    // MARK: Style
    /// true = dùng trong NavigationBar (height sẽ được quản lý bởi parent view)
    public var isNavigationStyle: Bool = true {
        didSet { updateStyle() }
    }

    // MARK: Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupEvents()
    }

    required init?(coder: NSCoder) {
        fatalError("EcoSearchTextField does not support nib/storyboard")
    }
}

// MARK: - Setup
private extension EcoSearchTextField {

    func setupUI() {
        borderStyle = .none
        layer.cornerRadius = 12
        clipsToBounds = true

        font = .systemFont(ofSize: 14)
        returnKeyType = .search
        autocorrectionType = .no
        autocapitalizationType = .none

        // Search icon
        searchIconView.image = UIImage(systemName: "magnifyingglass")
        searchIconView.tintColor = .secondaryLabel
        searchIconView.contentMode = .scaleAspectFit
        leftView = searchIconView
        leftViewMode = .always

        // Camera button
        cameraButton.setImage(
            UIImage(systemName: "camera.fill"),
            for: .normal
        )
        cameraButton.tintColor = .secondaryLabel
        cameraButton.contentMode = .scaleAspectFit
        cameraButton.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)
        
        // Tăng kích thước camera button - width thêm 4pt (từ 28 lên 32)
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButtonWidthConstraint = cameraButton.widthAnchor.constraint(equalToConstant: 32) // Tăng từ 28 lên 32
        cameraButtonHeightConstraint = cameraButton.heightAnchor.constraint(equalToConstant: 28)
        cameraButtonWidthConstraint?.isActive = true
        cameraButtonHeightConstraint?.isActive = true
        
        // Clear button
        clearButton.setImage(
            UIImage(systemName: "xmark.circle.fill"),
            for: .normal
        )
        clearButton.tintColor = .secondaryLabel

        rightStack.axis = .horizontal
        rightStack.spacing = 4
        // Camera button sẽ được thêm vào khi cần (trong apply state)
        rightStack.addArrangedSubview(clearButton)

        rightView = rightStack
        rightViewMode = .always // Đổi thành .always để camera button luôn hiển thị

        updateStyle()
    }

    func setupEvents() {
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(cameraTapped), for: .touchUpInside)
        delegate = self
    }
}

// MARK: - Layout Overrides
public extension EcoSearchTextField {
    
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        CGRect(x: 8, y: (bounds.height - 16) / 2, width: 16, height: 16)
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        CGRect(x: bounds.width - 28, y: (bounds.height - 20) / 2, width: 20, height: 20)
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 32))
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        textRect(forBounds: bounds)
    }
}

// MARK: - Apply State
public extension EcoSearchTextField {

    func apply(state: EcoSearchState) {
        // Preserve editing state nếu đang editing
        // Chỉ update isEditing nếu state.isEditing = true (để becomeFirstResponder)
        // Không update nếu state.isEditing = false và đang editing (để tránh ẩn bàn phím)
        let wasEditing = isFirstResponder
        self.searchState = state
        if wasEditing && !state.isEditing {
            // Đang editing nhưng state muốn set isEditing = false
            // Giữ nguyên editing state để không ẩn bàn phím
            self.searchState.isEditing = true
        }

        text = state.text
        placeholder = state.placeholder
        clearButton.isHidden = !state.showsClearButton
        
        // Setup camera button
        if state.showsCameraButton {
            // Thêm camera button vào rightStack nếu chưa có
            if !rightStack.arrangedSubviews.contains(cameraButton) {
                rightStack.insertArrangedSubview(cameraButton, at: 0) // Thêm vào đầu (bên trái clearButton)
            }
            // Update visibility dựa trên text
            updateCameraAndClearButtonVisibility()
        } else {
            // Xóa camera button khỏi rightStack nếu có
            if rightStack.arrangedSubviews.contains(cameraButton) {
                rightStack.removeArrangedSubview(cameraButton)
                cameraButton.removeFromSuperview()
            }
            cameraButton.isHidden = true
        }
        
        // Update backgroundColor if provided in state
        if let backgroundColor = state.backgroundColor {
            self.backgroundColor = backgroundColor
        }
        
        // Update border if provided in state
        if let borderWidth = state.borderWidth {
            layer.borderWidth = borderWidth
        }
        if let borderColor = state.borderColor {
            layer.borderColor = borderColor.cgColor
        }

        // Chỉ thay đổi editing state nếu thực sự cần thiết
        // Không tự động resignFirstResponder khi chỉ update text
        // Chỉ becomeFirstResponder nếu state.isEditing = true và hiện tại không đang editing
        if self.searchState.isEditing && !isFirstResponder {
            becomeFirstResponder()
        }
        // Không gọi resignFirstResponder() ở đây vì sẽ làm ẩn bàn phím khi user đang nhập
        // resignFirstResponder() chỉ được gọi khi submit search (trong textFieldShouldReturn)
    }
    
    /// Cập nhật visibility của camera và clear button dựa trên text
    private func updateCameraAndClearButtonVisibility() {
        let hasText = !(text?.isEmpty ?? true)
        let showsCamera = searchState.showsCameraButton
        
        if showsCamera {
            // Nếu có text: ẩn camera, hiện clear
            // Nếu không có text: hiện camera, ẩn clear
            cameraButton.isHidden = hasText
            clearButton.isHidden = !hasText || !searchState.showsClearButton
        } else {
            // Nếu không có camera button, chỉ quản lý clear button
            clearButton.isHidden = !hasText || !searchState.showsClearButton
        }
    }
}

// MARK: - Style
private extension EcoSearchTextField {

    func updateStyle() {
        // Default: no border, sẽ được set từ state nếu cần
        if isNavigationStyle {
            layer.borderWidth = 0
            backgroundColor = UIColor.black.withAlphaComponent(0.08)
            textColor = .label
            tintColor = .label
            // Height constraint sẽ được quản lý bởi parent view (EcoNavigationBarView)
            // Không tạo constraint ở đây để tránh conflict
            heightConstraint?.isActive = false
            heightConstraint = nil
        } else {
            backgroundColor = .white
            textColor = .label
            tintColor = .label
            layer.borderWidth = 1
            layer.borderColor = UIColor.separator.cgColor
            // Tạo hoặc update height constraint cho non-navigation style
            if heightConstraint == nil {
                heightConstraint = heightAnchor.constraint(equalToConstant: 40)
                heightConstraint?.isActive = true
            } else {
                heightConstraint?.constant = 40
            }
        }
    }
}

// MARK: - Actions
private extension EcoSearchTextField {

    @objc func textDidChange() {
        // Cập nhật visibility của camera và clear button khi text thay đổi
        updateCameraAndClearButtonVisibility()
        onTextChange?(text ?? "")
    }

    @objc func clearTapped() {
        text = ""
        // Cập nhật visibility sau khi clear text
        updateCameraAndClearButtonVisibility()
        onClear?()
        onTextChange?("")
    }
    
    @objc func cameraTapped() {
        print("📷 [EcoSearchTextField] Camera button tapped")
        print("📷 [EcoSearchTextField] onCameraTap callback: \(onCameraTap != nil ? "EXISTS" : "nil")")
        if let onCameraTap = onCameraTap {
            print("📷 [EcoSearchTextField] Calling onCameraTap callback")
            onCameraTap()
        } else {
            print("⚠️ [EcoSearchTextField] onCameraTap callback is nil - camera will not open")
        }
    }
}

// MARK: - UITextFieldDelegate
extension EcoSearchTextField: UITextFieldDelegate {

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Cho phép tất cả ký tự bao gồm dấu cách
        return true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Ẩn bàn phím nhưng giữ nguyên trạng thái text field
        resignFirstResponder()
        // Update isEditing trong state nhưng không trigger render lại navigation bar
        searchState.isEditing = false
        onSubmit?(text ?? "")
        return true
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        searchState.isEditing = true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        searchState.isEditing = false
    }
}
