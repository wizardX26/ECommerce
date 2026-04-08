//
//  EcoButton.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import UIKit

// MARK: - EcoButtonState

public enum EcoButtonState {
    case normal
    case loading
    case disabled
    case success
    case error
}

// MARK: - EcoButtonDelegate

public protocol EcoButtonDelegate: AnyObject {
    func buttonDidChangeState(_ button: EcoButton, from oldState: EcoButtonState, to newState: EcoButtonState)
    func buttonDidTap(_ button: EcoButton)
}

public extension EcoButtonDelegate {
    func buttonDidChangeState(_ button: EcoButton, from oldState: EcoButtonState, to newState: EcoButtonState) {}
    func buttonDidTap(_ button: EcoButton) {}
}

// MARK: - EcoButton

@IBDesignable
open class EcoButton: UIButton {
    
    // MARK: - Properties
    
    public weak var ecoDelegate: EcoButtonDelegate?
    
    public var buttonState: EcoButtonState = .normal {
        didSet {
            guard buttonState != oldValue else { return }
            updateState(from: oldValue, to: buttonState)
            ecoDelegate?.buttonDidChangeState(self, from: oldValue, to: buttonState)
        }
    }
    
    // MARK: - UI Components
    
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let successIconView = UIImageView()
    private let errorIconView = UIImageView()
    
    private var originalTitle: String?
    private var originalImage: UIImage?
    
    // MARK: - Styling Properties
    
    @IBInspectable public var normalBackgroundColor: UIColor = Colors.tokenRainbowBlueEnd {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable public var disabledBackgroundColor: UIColor = Colors.tokenDark10 {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable public var successBackgroundColor: UIColor = Colors.tokenGreen100 {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable public var errorBackgroundColor: UIColor = Colors.tokenRed100 {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable public var normalTitleColor: UIColor = Colors.tokenWhite {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable public var disabledTitleColor: UIColor = Colors.tokenDark40 {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable public var successTitleColor: UIColor = Colors.tokenWhite {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable public var errorTitleColor: UIColor = Colors.tokenWhite {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable public var titleFont: UIFont = Typography.fontMedium18 {
        didSet {
            titleLabel?.font = titleFont
        }
    }
    
    @IBInspectable public var cornerRadius: CGFloat = BorderRadius.tokenBorderRadius12 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable public var hasShadow: Bool = true {
        didSet {
            updateShadow()
        }
    }
    
    @IBInspectable public var shadowColor: UIColor = Colors.tokenRainbowBlueEnd {
        didSet {
            updateShadow()
        }
    }
    
    @IBInspectable public var shadowOpacity: Float = Shadows.tokenShadowOpacity30 {
        didSet {
            updateShadow()
        }
    }
    
    @IBInspectable public var shadowOffset: CGSize = Shadows.tokenShadowOffset08 {
        didSet {
            updateShadow()
        }
    }
    
    @IBInspectable public var shadowRadius: CGFloat = Sizing.tokenSizing08 {
        didSet {
            updateShadow()
        }
    }
    
    @IBInspectable public var loadingIndicatorColor: UIColor = Colors.tokenWhite {
        didSet {
            loadingIndicator.color = loadingIndicatorColor
        }
    }
    
    @IBInspectable public var showsSuccessIcon: Bool = true {
        didSet {
            updateAppearance()
        }
    }
    
    @IBInspectable public var showsErrorIcon: Bool = true {
        didSet {
            updateAppearance()
        }
    }
    
    // MARK: - Animation Properties
    
    public var animationDuration: TimeInterval = 0.3
    public var usesSpringAnimation: Bool = true
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    // MARK: - Setup
    
    private func setupButton() {
        // Basic setup
        layer.cornerRadius = cornerRadius
        clipsToBounds = false
        
        // Disable automatic tint adjustment when disabled to maintain colors during loading
        adjustsImageWhenDisabled = false
        adjustsImageWhenHighlighted = false
        
        // Title styling
        titleLabel?.font = titleFont
        setTitleColor(normalTitleColor, for: .normal)
        
        // Setup loading indicator
        setupLoadingIndicator()
        
        // Setup success icon
        setupSuccessIcon()
        
        // Setup error icon
        setupErrorIcon()
        
        // Add target
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        // Initial state
        updateAppearance()
        updateShadow()
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = loadingIndicatorColor
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func setupSuccessIcon() {
        successIconView.image = UIImage(systemName: "checkmark")
        successIconView.tintColor = successTitleColor
        successIconView.contentMode = .scaleAspectFit
        successIconView.translatesAutoresizingMaskIntoConstraints = false
        successIconView.isHidden = true
        addSubview(successIconView)
        
        NSLayoutConstraint.activate([
            successIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            successIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            successIconView.widthAnchor.constraint(equalToConstant: Sizing.tokenSizing24),
            successIconView.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing24)
        ])
    }
    
    private func setupErrorIcon() {
        errorIconView.image = UIImage(systemName: "xmark")
        errorIconView.tintColor = errorTitleColor
        errorIconView.contentMode = .scaleAspectFit
        errorIconView.translatesAutoresizingMaskIntoConstraints = false
        errorIconView.isHidden = true
        addSubview(errorIconView)
        
        NSLayoutConstraint.activate([
            errorIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            errorIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            errorIconView.widthAnchor.constraint(equalToConstant: Sizing.tokenSizing24),
            errorIconView.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing24)
        ])
    }
    
    // MARK: - State Updates
    
    private func updateState(from oldState: EcoButtonState, to newState: EcoButtonState) {
        // Save original title and image if transitioning to loading
        if newState == .loading && oldState == .normal {
            originalTitle = currentTitle
            originalImage = currentImage
        }
        
        // Update appearance
        updateAppearance()
        
        // Animate transition
        animateStateTransition(from: oldState, to: newState)
    }
    
    private func updateAppearance() {
        switch buttonState {
        case .normal:
            backgroundColor = normalBackgroundColor
            setTitleColor(normalTitleColor, for: .normal)
            isEnabled = true
            isUserInteractionEnabled = true
            hideAllIndicators()
            showTitle()
            
        case .loading:
            backgroundColor = normalBackgroundColor
            setTitleColor(normalTitleColor, for: .normal)
            // Keep button enabled but prevent interaction through buttonTapped check
            // This maintains the normal tintColor/appearance
            isEnabled = true
            isUserInteractionEnabled = false
            showLoadingIndicator()
            hideTitle()
            
        case .disabled:
            backgroundColor = disabledBackgroundColor
            setTitleColor(disabledTitleColor, for: .normal)
            isEnabled = false
            isUserInteractionEnabled = false
            hideAllIndicators()
            showTitle()
            
        case .success:
            backgroundColor = successBackgroundColor
            setTitleColor(successTitleColor, for: .normal)
            isEnabled = false
            if showsSuccessIcon {
                showSuccessIcon()
            } else {
                showTitle()
            }
            hideLoadingIndicator()
            
        case .error:
            backgroundColor = errorBackgroundColor
            setTitleColor(errorTitleColor, for: .normal)
            isEnabled = false
            if showsErrorIcon {
                showErrorIcon()
            } else {
                showTitle()
            }
            hideLoadingIndicator()
        }
        
        updateShadow()
    }
    
    // MARK: - Indicator Management
    
    private func showLoadingIndicator() {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
    }
    
    private func showSuccessIcon() {
        successIconView.isHidden = false
        titleLabel?.isHidden = true
        imageView?.isHidden = true
    }
    
    private func showErrorIcon() {
        errorIconView.isHidden = false
        titleLabel?.isHidden = true
        imageView?.isHidden = true
    }
    
    private func hideAllIndicators() {
        hideLoadingIndicator()
        successIconView.isHidden = true
        errorIconView.isHidden = true
    }
    
    private func showTitle() {
        titleLabel?.isHidden = false
        imageView?.isHidden = false
    }
    
    private func hideTitle() {
        titleLabel?.isHidden = true
        imageView?.isHidden = true
    }
    
    // MARK: - Shadow
    
    private func updateShadow() {
        guard hasShadow else {
            layer.shadowColor = nil
            layer.shadowOpacity = 0
            return
        }
        
        layer.shadowColor = shadowColor.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowOffset = shadowOffset
        layer.shadowRadius = shadowRadius
        layer.masksToBounds = false
    }
    
    // MARK: - Animation
    
    private func animateStateTransition(from oldState: EcoButtonState, to newState: EcoButtonState) {
        guard usesSpringAnimation else {
            UIView.animate(withDuration: animationDuration) {
                self.layoutIfNeeded()
            }
            return
        }
        
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: {
                self.layoutIfNeeded()
            }
        )
    }
    
    // MARK: - Actions
    
    @objc private func buttonTapped() {
        guard buttonState != .loading && buttonState != .disabled else { return }
        ecoDelegate?.buttonDidTap(self)
    }
    
    // MARK: - Public Methods
    
    public func setLoading(_ isLoading: Bool) {
        buttonState = isLoading ? .loading : .normal
    }
    
    public func setEnabled(_ enabled: Bool) {
        buttonState = enabled ? .normal : .disabled
    }
    
    public func setSuccess(_ success: Bool, animated: Bool = true) {
        if success {
            buttonState = .success
            if animated {
                // Auto reset to normal after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.buttonState = .normal
                }
            }
        } else {
            buttonState = .normal
        }
    }
    
    public func setError(_ error: Bool, animated: Bool = true) {
        if error {
            buttonState = .error
            if animated {
                // Auto reset to normal after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.buttonState = .normal
                }
            }
        } else {
            buttonState = .normal
        }
    }
    
    public func reset() {
        buttonState = .normal
    }
    
    // MARK: - Overrides
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateShadow()
    }
    
    public override var isEnabled: Bool {
        didSet {
            if !isEnabled && buttonState == .normal {
                buttonState = .disabled
            } else if isEnabled && buttonState == .disabled {
                buttonState = .normal
            }
        }
    }
    
    public override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        if state == .normal {
            originalTitle = title
        }
    }
    
    public override func setImage(_ image: UIImage?, for state: UIControl.State) {
        super.setImage(image, for: state)
        if state == .normal {
            originalImage = image
        }
    }
}

// MARK: - Convenience Initializers

public extension EcoButton {
    
    /// Create a primary button with default styling
    static func primary(title: String) -> EcoButton {
        let button = EcoButton()
        button.setTitle(title, for: .normal)
        button.normalBackgroundColor = Colors.tokenRainbowBlueEnd
        button.normalTitleColor = Colors.tokenWhite
        button.titleFont = Typography.fontMedium18
        button.cornerRadius = BorderRadius.tokenBorderRadius12
        button.hasShadow = true
        return button
    }
    
    /// Create a secondary button with default styling
    static func secondary(title: String) -> EcoButton {
        let button = EcoButton()
        button.setTitle(title, for: .normal)
        button.normalBackgroundColor = Colors.tokenDark02
        button.normalTitleColor = Colors.tokenDark100
        button.titleFont = Typography.fontMedium18
        button.cornerRadius = BorderRadius.tokenBorderRadius12
        button.hasShadow = false
        return button
    }
    
    /// Create a button for Login/Signup screens
    static func authButton(title: String) -> EcoButton {
        let button = EcoButton()
        button.setTitle(title, for: .normal)
        button.normalBackgroundColor = Colors.tokenRainbowBlueEnd
        button.normalTitleColor = Colors.tokenWhite
        button.titleFont = Typography.fontMedium18
        button.cornerRadius = BorderRadius.tokenBorderRadius12
        button.hasShadow = true
        button.shadowColor = Colors.tokenRainbowBlueEnd
        button.shadowOpacity = Shadows.tokenShadowOpacity30
        button.shadowOffset = Shadows.tokenShadowOffset08
        button.shadowRadius = Sizing.tokenSizing08
        return button
    }
}
