//
//  EcoNavigationBarView.swift
//  ECommerce
//
//  Created by wizard.os25 on 8/1/26.
//

import UIKit
import ObjectiveC

public protocol EcoNavigationBarViewType: UIView {
    func render(state: EcoNavigationState, animated: Bool)
    func updateScroll(progress: CGFloat)
    var onLeftItemTap: (() -> Void)? { get set }
    var onRightItemTap: ((Int) -> Void)? { get set }
}

public final class EcoNavigationBarView: UIView, EcoNavigationBarViewType {

    // MARK: - Constants
    
    public static let height: CGFloat = 44

    // MARK: - UI Components
    
    private let backgroundView = UIView()
    private let blurView = UIVisualEffectView()

    private let leftStack = UIStackView()
    private let rightStack = UIStackView()

    private let titleLabel = UILabel()
    private let searchTextField = EcoSearchTextField()
    
    // MARK: - Scroll Behavior State
    
    var scrollOffset: CGFloat = 0 // Made internal để có thể access từ EcoNavigationBarViewController
    private var isCollapsed: Bool = false
    var currentState: EcoNavigationState? // Made internal để có thể access từ EcoNavigationBarViewController
    
    // MARK: - Constraints for Scroll Behavior
    
    private var searchFieldLeadingConstraint: NSLayoutConstraint?
    private var searchFieldTrailingConstraint: NSLayoutConstraint?
    private var searchFieldCenterXConstraint: NSLayoutConstraint?
    private var searchFieldWidthConstraint: NSLayoutConstraint?
    private var searchFieldHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Callbacks
    
    public var onHeightChange: ((CGFloat) -> Void)?
    
    // MARK: - Item Tap Handlers
    
    public var onLeftItemTap: (() -> Void)?
    public var onRightItemTap: ((Int) -> Void)?

    // MARK: - Init
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("EcoNavigationBarView does not support nib")
    }
}

// MARK: - Setup UI

private extension EcoNavigationBarView {

    func setupUI() {
        backgroundColor = .clear
        // Ensure view can receive touch events
        isUserInteractionEnabled = true

        // Background
        addSubview(backgroundView)
        backgroundView.frame = bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.isHidden = true
        backgroundView.addSubview(blurView)

        // Left stack
        leftStack.axis = .horizontal
        leftStack.spacing = 8
        leftStack.alignment = .center
        leftStack.distribution = .fill
        leftStack.isHidden = false
        leftStack.isUserInteractionEnabled = true
        addSubview(leftStack)

        // Right stack
        rightStack.axis = .horizontal
        rightStack.spacing = 12
        rightStack.alignment = .center
        rightStack.distribution = .fill
        rightStack.isHidden = false
        rightStack.isUserInteractionEnabled = true
        addSubview(rightStack)

        // Title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byTruncatingTail
        addSubview(titleLabel)

        // Search TextField
        searchTextField.isNavigationStyle = true
        searchTextField.isHidden = true
        addSubview(searchTextField)

        layoutUI()
    }

    func layoutUI() {
        let padding: CGFloat = 12

        leftStack.translatesAutoresizingMaskIntoConstraints = false
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.translatesAutoresizingMaskIntoConstraints = false

        // Search field constraints - will be updated during scroll
        let searchLeading = searchTextField.leadingAnchor.constraint(equalTo: leftStack.trailingAnchor, constant: 8)
        let searchTrailing = searchTextField.trailingAnchor.constraint(equalTo: rightStack.leadingAnchor, constant: -8)
        let searchCenterX = searchTextField.centerXAnchor.constraint(equalTo: centerXAnchor)
        searchCenterX.isActive = false // Initially inactive
        
        searchFieldLeadingConstraint = searchLeading
        searchFieldTrailingConstraint = searchTrailing
        searchFieldCenterXConstraint = searchCenterX

        NSLayoutConstraint.activate([
            leftStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            leftStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            rightStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            rightStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leftStack.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: rightStack.leadingAnchor, constant: -8),

            searchLeading,
            searchTrailing,
            searchTextField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // Search field height constraint - will be updated based on state
        // Default height: 32, will be updated when state is applied
        let searchHeight = searchTextField.heightAnchor.constraint(equalToConstant: 32)
        searchHeight.isActive = true
        searchFieldHeightConstraint = searchHeight
    }
}

// MARK: - Render State

public extension EcoNavigationBarView {

    func render(state: EcoNavigationState, animated: Bool) {
        // Store state for access in makeView
        currentState = state
        let previousState = self.currentState
        self.currentState = state

        applyBackground(state.background, customColor: state.backgroundColor)
        
        // Debug logging
        print("🔵 [EcoNavigationBarView] render - View frame: \(frame), bounds: \(bounds)")
        print("   - Background applied: \(state.background)")
        print("   - isHidden: \(isHidden), alpha: \(alpha)")

        // Title
        titleLabel.text = state.title
        
        // Custom title styling
        if let titleFont = state.titleFont {
            titleLabel.font = titleFont
        }
        if let titleColor = state.titleColor {
            titleLabel.textColor = titleColor
        }
        
        // Chỉ update visibility nếu không đang editing và không có text để tránh reset khi user đang nhập hoặc đã nhập
        let isEditing = searchTextField.isFirstResponder || (state.searchState?.isEditing ?? false)
        let hasText = !(state.searchState?.text.isEmpty ?? true)
        
        // For collapseWithSearch behavior: initially show title, hide search
        // Search will appear when scrolling
        // Nhưng nếu đang editing hoặc có text, giữ nguyên trạng thái hiện tại (search field hiển thị)
        if !isEditing && !hasText {
            // Chỉ reset khi không editing và không có text
            if state.scrollBehavior == .collapseWithSearch {
                titleLabel.isHidden = false
                titleLabel.alpha = 1.0
                searchTextField.isHidden = true
                searchTextField.alpha = 0
            } else {
                // Normal behavior: show title or search based on showsSearch
                titleLabel.isHidden = state.showsSearch
                searchTextField.isHidden = !state.showsSearch
            }
        } else {
            // Nếu có text hoặc đang editing, đảm bảo search field hiển thị
            if state.showsSearch {
                titleLabel.isHidden = true
                searchTextField.isHidden = false
                searchTextField.alpha = 1.0
            }
        }
        
        // Search TextField
        if state.showsSearch, var searchState = state.searchState {
            // Đồng bộ màu sắc: nếu searchState không có backgroundColor, tự động tính từ navigationBar background
            if searchState.backgroundColor == nil {
                searchState.backgroundColor = calculateSearchFieldBackgroundColor(from: state)
            }
            
            searchTextField.apply(state: searchState)
            
            // Update search field height: use state.height if provided, otherwise keep current/default
            if let height = searchState.height {
                searchFieldHeightConstraint?.constant = height
            }
            // If no height in state, keep the default height (32) set in layoutUI()
        }

        // Debug logging
        print("🔵 [EcoNavigationBarView] render - LeftItem: \(state.leftItem != nil ? "EXISTS" : "nil"), RightItems: \(state.rightItems.count)")
        
        render(stack: leftStack, items: state.leftItem.map { [$0] } ?? [])
        render(stack: rightStack, items: state.rightItems)
        
        print("🔵 [EcoNavigationBarView] render - LeftStack arrangedSubviews: \(leftStack.arrangedSubviews.count), RightStack arrangedSubviews: \(rightStack.arrangedSubviews.count)")
        
        // Apply button tint color if provided
        if let buttonTintColor = state.buttonTintColor {
            print("🔵 [EcoNavigationBarView] Applying button tint color: \(buttonTintColor)")
            applyButtonTintColor(buttonTintColor, to: leftStack)
            applyButtonTintColor(buttonTintColor, to: rightStack)
        } else {
            print("⚠️ [EcoNavigationBarView] No button tint color provided")
        }
        
        // Update search field layout: centerX, centerY, leading và trailing 12pt khi không có left/right items
        let hasLeftItems = state.leftItem != nil
        let hasRightItems = !state.rightItems.isEmpty
        
        if state.showsSearch && !hasLeftItems && !hasRightItems {
            // Không có left/right items: center search field với padding 12pt
            searchFieldLeadingConstraint?.isActive = false
            searchFieldTrailingConstraint?.isActive = false
            
            if searchFieldCenterXConstraint?.isActive != true {
                searchFieldCenterXConstraint?.isActive = true
            }
            
            // Create or update width constraint for search field when centered
            let searchPadding: CGFloat = 12
            if searchFieldWidthConstraint == nil {
                let searchWidth = searchTextField.widthAnchor.constraint(
                    equalTo: widthAnchor,
                    constant: -(searchPadding * 2)
                )
                searchWidth.priority = .required
                searchWidth.isActive = true
                searchFieldWidthConstraint = searchWidth
            } else {
                searchFieldWidthConstraint?.constant = -(searchPadding * 2)
                searchFieldWidthConstraint?.isActive = true
            }
        } else {
            // Có left/right items: layout bình thường giữa left và right stacks
            searchFieldCenterXConstraint?.isActive = false
            searchFieldWidthConstraint?.isActive = false
            searchFieldLeadingConstraint?.isActive = true
            searchFieldTrailingConstraint?.isActive = true
        }
        
        // Ensure stacks are visible
        leftStack.isHidden = false
        rightStack.isHidden = false
        leftStack.alpha = 1.0
        rightStack.alpha = 1.0
        print("🔵 [EcoNavigationBarView] Stacks visibility - leftStack.isHidden: \(leftStack.isHidden), rightStack.isHidden: \(rightStack.isHidden)")

        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
                self.layoutIfNeeded()
            }
        }
    }
    
    /// Get search text field for external access
    var searchField: EcoSearchTextField {
        searchTextField
    }
}

// MARK: - Private Rendering Helpers

private extension EcoNavigationBarView {

    func applyBackground(_ background: EcoNavigationBackground, customColor: UIColor? = nil) {
        blurView.isHidden = true

        switch background {
        case .transparent:
            backgroundView.backgroundColor = customColor ?? .clear

        case .solid(let color):
            backgroundView.backgroundColor = customColor ?? color

        case .blur(let style):
            blurView.effect = UIBlurEffect(style: style)
            blurView.isHidden = false
            backgroundView.backgroundColor = customColor
        }
    }
    
    /// Tính toán màu nền cho search field dựa trên navigation bar background
    func calculateSearchFieldBackgroundColor(from state: EcoNavigationState) -> UIColor {
        // Nếu có backgroundColor từ state, sử dụng nó
        if let backgroundColor = state.backgroundColor {
            // Tính toán màu tối hơn hoặc sáng hơn dựa trên màu nền
            return calculateContrastColor(for: backgroundColor)
        }
        
        // Nếu không có, dựa vào background type
        switch state.background {
        case .transparent:
            return UIColor.black.withAlphaComponent(0.08)
        case .solid(let color):
            return calculateContrastColor(for: color)
        case .blur:
            return UIColor.black.withAlphaComponent(0.08)
        }
    }
    
    /// Tính toán màu tương phản cho search field
    private func calculateContrastColor(for color: UIColor) -> UIColor {
        // Lấy các thành phần RGB
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Tính độ sáng (luminance)
        let luminance = (0.299 * red + 0.587 * green + 0.114 * blue)
        
        // Nếu nền sáng, làm tối hơn; nếu nền tối, làm sáng hơn
        if luminance > 0.5 {
            // Nền sáng: tạo màu tối hơn với alpha
            return UIColor.black.withAlphaComponent(0.08)
        } else {
            // Nền tối: tạo màu sáng hơn với alpha
            return UIColor.white.withAlphaComponent(0.15)
        }
    }

    func render(stack: UIStackView, items: [EcoNavItem]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        print("🔵 [EcoNavigationBarView] render(stack) - Items count: \(items.count), isLeftStack: \(stack === leftStack)")
        
        for (index, item) in items.enumerated() {
            let isLeftStack = (stack === leftStack)
            let view = makeView(for: item, index: index, isLeft: isLeftStack)
            // Ensure view can receive touch events
            view.isUserInteractionEnabled = true
            stack.addArrangedSubview(view)
            print("   ✅ Added item \(index) to \(isLeftStack ? "left" : "right") stack")
            print("      - View type: \(type(of: view))")
            print("      - isUserInteractionEnabled: \(view.isUserInteractionEnabled)")
            if let button = view as? UIButton {
                print("      - Button isEnabled: \(button.isEnabled)")
                print("      - Button frame: \(button.frame)")
            }
        }
        
        // Ensure stack can receive touch events
        stack.isUserInteractionEnabled = true
        print("   ✅ Stack isUserInteractionEnabled: \(stack.isUserInteractionEnabled)")
    }
    
    func applyButtonTintColor(_ color: UIColor, to stack: UIStackView) {
        print("🔵 [EcoNavigationBarView] applyButtonTintColor - stack arrangedSubviews: \(stack.arrangedSubviews.count)")
        for (index, view) in stack.arrangedSubviews.enumerated() {
            if let button = view as? UIButton {
                // Button trực tiếp trong stack
                button.tintColor = color
                print("   ✅ Applied tint color to button \(index), tintColor: \(button.tintColor?.description ?? "nil")")
            } else {
                // ✅ QUAN TRỌNG: Nếu view là containerView (circular background), tìm button bên trong
                if let containerView = view as? UIView {
                    // Tìm button trong subviews của containerView
                    for subview in containerView.subviews {
                        if let button = subview as? UIButton {
                            button.tintColor = color
                            print("   ✅ Applied tint color to button inside containerView \(index), tintColor: \(button.tintColor?.description ?? "nil")")
                            break
                        }
                    }
                } else {
                    print("   ⚠️ View \(index) is not a UIButton or containerView: \(type(of: view))")
                }
            }
        }
    }

    func makeView(for item: EcoNavItem, index: Int, isLeft: Bool) -> UIView {
        let button = UIButton(type: .system)
        
        // Set button size and content mode
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        // Ensure button can receive touch events
        button.isUserInteractionEnabled = true
        button.isEnabled = true
        
        // Store action closure using associated object
        let actionWrapper = ButtonActionWrapper(action: { [weak self] in
            print("🔵 [EcoNavigationBarView] ButtonActionWrapper action called - isLeft: \(isLeft), index: \(index)")
            // First execute the action from state
            switch item {
            case .back(let action):
                print("   📍 Executing back button action from state")
                action()
            case .close(let action), .icon(_, let action), 
                 .text(_, let action), .cart(_, let action):
                action()
            }
            
            // Then notify handlers if set
            if isLeft {
                print("   📍 Calling onLeftItemTap callback")
                self?.onLeftItemTap?()
            } else {
                print("   📍 Calling onRightItemTap callback with index: \(index)")
                self?.onRightItemTap?(index)
            }
        })
        
        // Store wrapper to prevent deallocation
        objc_setAssociatedObject(button, &AssociatedKeys.actionWrapper, actionWrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        switch item {
        case .back:
            // Check backButtonStyle from current state
            let backButtonStyle = currentState?.backButtonStyle ?? .circular
            
            if backButtonStyle == .circular {
                // Create container view for circular background
                let containerView = UIView()
                containerView.translatesAutoresizingMaskIntoConstraints = false
                // ✅ QUAN TRỌNG: Tăng alpha để nổi bật hơn trên nền trong suốt
                // Sử dụng màu đen với alpha cao hơn để tạo cảm giác nổi lên
                containerView.backgroundColor = UIColor.black.withAlphaComponent(0.3) // Tăng từ 0.1 lên 0.3 để nổi bật hơn
                containerView.layer.cornerRadius = 18 // Hình tròn (36/2)
                containerView.isUserInteractionEnabled = false // Container không nhận touch, chỉ button nhận
                
                // Add container to button (button will be added to stack later)
                // For now, we'll add container as a wrapper
                containerView.addSubview(button)
                
                if let chevronImage = UIImage(systemName: "chevron.left") {
                    button.setImage(chevronImage, for: .normal)
                    print("   ✅ [EcoNavigationBarView] Back button image set: chevron.left")
                } else {
                    print("   ⚠️ [EcoNavigationBarView] Failed to load chevron.left image")
                }
                button.imageView?.contentMode = .scaleAspectFit
                button.addTarget(actionWrapper, action: #selector(ButtonActionWrapper.execute), for: .touchUpInside)
                
                // Set button size - smaller for circular button
                button.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    button.widthAnchor.constraint(equalToConstant: 36),
                    button.heightAnchor.constraint(equalToConstant: 36),
                    button.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                    button.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                ])
                
                // Set container size
                NSLayoutConstraint.activate([
                    containerView.widthAnchor.constraint(equalToConstant: 36),
                    containerView.heightAnchor.constraint(equalToConstant: 36)
                ])
                
                // Ensure button is visible and interactive
                button.isHidden = false
                button.alpha = 1.0
                button.isUserInteractionEnabled = true
                button.isEnabled = true
                containerView.isHidden = false
                containerView.alpha = 1.0
                
                // Tint color sẽ được apply từ state.buttonTintColor sau
                // Default là white để nổi bật trên nền trong suốt
                button.tintColor = .white
                
                print("   ✅ [EcoNavigationBarView] Created back button with circular background:")
                print("      - Container size: 36x36")
                print("      - Button size: 36x36")
                print("      - Corner radius: 18")
                print("      - Background: black with alpha 0.1")
                
                // Return container view instead of button for back case
                return containerView
            } else {
                // Simple back button without circular background
                if let chevronImage = UIImage(systemName: "chevron.left") {
                    button.setImage(chevronImage, for: .normal)
                    print("   ✅ [EcoNavigationBarView] Back button image set: chevron.left (simple)")
                } else {
                    print("   ⚠️ [EcoNavigationBarView] Failed to load chevron.left image")
                }
                button.imageView?.contentMode = .scaleAspectFit
                button.addTarget(actionWrapper, action: #selector(ButtonActionWrapper.execute), for: .touchUpInside)
                
                // Set button size - standard size for simple button
                button.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    button.widthAnchor.constraint(equalToConstant: 44),
                    button.heightAnchor.constraint(equalToConstant: 44)
                ])
                
                // Tint color sẽ được apply từ state.buttonTintColor sau
                // Default là white để nổi bật trên nền trong suốt
                button.tintColor = .white
                
                print("   ✅ [EcoNavigationBarView] Created simple back button (no circular background)")
                
                return button
            }

        case .close:
            button.setImage(UIImage(systemName: "xmark"), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.addTarget(actionWrapper, action: #selector(ButtonActionWrapper.execute), for: .touchUpInside)
            button.widthAnchor.constraint(equalToConstant: 44).isActive = true
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true

        case .icon(let image, _):
            button.setImage(image, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.addTarget(actionWrapper, action: #selector(ButtonActionWrapper.execute), for: .touchUpInside)
            
            // Nếu là right item, check backButtonStyle để quyết định circular hay simple
            if !isLeft {
                let backButtonStyle = currentState?.backButtonStyle ?? .circular
                
                // Nếu backButtonStyle là simple, right items cũng dùng simple style (không có circular background)
                if backButtonStyle == .simple {
                    button.widthAnchor.constraint(equalToConstant: 44).isActive = true
                    button.heightAnchor.constraint(equalToConstant: 44).isActive = true
                    button.tintColor = Colors.tokenDark100
                } else {
                    // Circular style - tạo circular background
                    let containerView = UIView()
                    containerView.translatesAutoresizingMaskIntoConstraints = false
                    containerView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
                    containerView.layer.cornerRadius = 18
                    containerView.isUserInteractionEnabled = false
                    
                    containerView.addSubview(button)
                    button.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        button.widthAnchor.constraint(equalToConstant: 36),
                        button.heightAnchor.constraint(equalToConstant: 36),
                        button.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                        button.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                    ])
                    
                    NSLayoutConstraint.activate([
                        containerView.widthAnchor.constraint(equalToConstant: 36),
                        containerView.heightAnchor.constraint(equalToConstant: 36)
                    ])
                    
                    button.tintColor = Colors.tokenDark100
                    return containerView
                }
            } else {
                button.widthAnchor.constraint(equalToConstant: 44).isActive = true
                button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            }

        case .text(let title, _):
            button.setTitle(title, for: .normal)
            button.addTarget(actionWrapper, action: #selector(ButtonActionWrapper.execute), for: .touchUpInside)

        case .cart:
            button.setImage(UIImage(systemName: "cart"), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.addTarget(actionWrapper, action: #selector(ButtonActionWrapper.execute), for: .touchUpInside)
            
            // Nếu là right item, check backButtonStyle để quyết định circular hay simple
            if !isLeft {
                let backButtonStyle = currentState?.backButtonStyle ?? .circular
                
                // Nếu backButtonStyle là simple, right items cũng dùng simple style (không có circular background)
                if backButtonStyle == .simple {
                    button.widthAnchor.constraint(equalToConstant: 44).isActive = true
                    button.heightAnchor.constraint(equalToConstant: 44).isActive = true
                    button.tintColor = Colors.tokenDark100
                } else {
                    // Circular style - tạo circular background
                    let containerView = UIView()
                    containerView.translatesAutoresizingMaskIntoConstraints = false
                    // ✅ QUAN TRỌNG: Tăng alpha để nổi bật hơn trên nền trong suốt
                    containerView.backgroundColor = UIColor.black.withAlphaComponent(0.3) // Tăng từ 0.1 lên 0.3
                    containerView.layer.cornerRadius = 18
                    containerView.isUserInteractionEnabled = false
                    
                    containerView.addSubview(button)
                    button.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        button.widthAnchor.constraint(equalToConstant: 36),
                        button.heightAnchor.constraint(equalToConstant: 36),
                        button.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                        button.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
                    ])
                    
                    NSLayoutConstraint.activate([
                        containerView.widthAnchor.constraint(equalToConstant: 36),
                        containerView.heightAnchor.constraint(equalToConstant: 36)
                    ])
                    
                    // Tint color sẽ được apply từ state.buttonTintColor sau
                    button.tintColor = Colors.tokenDark100 // Default, sẽ được override
                    return containerView
                }
            } else {
                button.widthAnchor.constraint(equalToConstant: 44).isActive = true
                button.heightAnchor.constraint(equalToConstant: 44).isActive = true
            }
        }
        
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }
}

// MARK: - Scroll Behavior

public extension EcoNavigationBarView {

    func updateScroll(progress: CGFloat) {
        guard let state = currentState else { return }
        scrollOffset = progress
        
        switch state.scrollBehavior {
        case .default:
            // No special behavior
            break
            
        case .collapseOnScroll:
            handleCollapseOnScroll(offset: progress)
            
        case .fadeOnScroll:
            handleFadeOnScroll(offset: progress)
            
        case .sticky:
            // Always visible, no change
            break
            
        case .hideOnScroll:
            handleHideOnScroll(offset: progress)
            
        case .collapseWithSearch:
            handleCollapseWithSearch(offset: progress, initialState: state)
        }
    }
    
    private func handleCollapseOnScroll(offset: CGFloat) {
        let threshold: CGFloat = 50
        let shouldCollapse = offset > threshold
        
        if shouldCollapse != isCollapsed {
            isCollapsed = shouldCollapse
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.alpha = shouldCollapse ? 0.7 : 1.0
                self.transform = shouldCollapse ? CGAffineTransform(translationX: 0, y: -10) : .identity
            }
        }
    }
    
    private func handleFadeOnScroll(offset: CGFloat) {
        let maxOffset: CGFloat = 100
        let progress = min(max(offset / maxOffset, 0), 1)
        let alpha = 1.0 - (progress * 0.5) // Fade to 50% opacity
        
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveLinear]) {
            self.alpha = alpha
            self.backgroundView.alpha = alpha
            self.titleLabel.alpha = alpha
            self.searchTextField.alpha = alpha
        }
    }
    
    private func handleHideOnScroll(offset: CGFloat) {
        let threshold: CGFloat = 30
        let shouldHide = offset > threshold
        
        if shouldHide != isCollapsed {
            isCollapsed = shouldHide
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.transform = shouldHide ? CGAffineTransform(translationX: 0, y: -self.bounds.height) : .identity
            }
        }
    }
    
    private func handleCollapseWithSearch(offset: CGFloat, initialState: EcoNavigationState) {
        let threshold: CGFloat = 50
        let maxOffset: CGFloat = 100
        let progress = min(max((offset - threshold) / (maxOffset - threshold), 0), 1)
        
        guard let initialHeight = initialState.height else { return }
        // Use collapsedHeight from state if provided, otherwise default to 44pt
        let collapsedHeight = initialState.collapsedHeight ?? EcoNavigationBarMetrics.barHeight
        let targetHeight = initialHeight - (initialHeight - collapsedHeight) * progress
        
        // Update height
        onHeightChange?(targetHeight)
        
        // Hide/show title with fade
        titleLabel.alpha = 1.0 - progress
        titleLabel.isHidden = progress > 0.5
        
        // Update background: transparent -> white when scrolling
        if progress > 0.1 {
            // Change background to white when scrolling
            if case .transparent = initialState.background {
                backgroundView.backgroundColor = .white
                blurView.isHidden = true
            }
        } else {
            // Restore transparent background when at top
            if case .transparent = initialState.background {
                backgroundView.backgroundColor = .clear
                blurView.isHidden = true
            }
        }
        
        // Show search and update layout (even if initially hidden, show when scrolling)
        let shouldShowSearch = progress > 0.1
        if shouldShowSearch {
            searchTextField.isHidden = false
            searchTextField.alpha = progress // Fade in as scroll progresses
            // Đảm bảo search field có thể tương tác khi hiển thị
            searchTextField.isUserInteractionEnabled = true
            
            // Update search state khi collapse: bỏ camera button, chỉ giữ clear button
            // Chỉ cập nhật khi collapse đủ (progress > 0.1) để tránh flickering
            if let currentSearchState = initialState.searchState, currentSearchState.showsCameraButton {
                // Kiểm tra xem đã cập nhật state chưa để tránh apply nhiều lần
                if searchTextField.searchState.showsCameraButton {
                    // Tạo search state mới với camera button disabled và clear button enabled
                    let collapsedSearchState = EcoSearchState(
                        text: searchTextField.searchState.text, // Giữ text hiện tại
                        placeholder: currentSearchState.placeholder,
                        isEditing: searchTextField.searchState.isEditing, // Giữ editing state
                        showsClearButton: true,
                        showsCameraButton: false, // Bỏ camera button khi collapse
                        height: currentSearchState.height,
                        backgroundColor: currentSearchState.backgroundColor,
                        borderWidth: currentSearchState.borderWidth,
                        borderColor: currentSearchState.borderColor
                    )
                    searchTextField.apply(state: collapsedSearchState)
                }
            }
        } else {
            // Only hide if it was initially shown
            if initialState.showsSearch {
                searchTextField.isHidden = true
                searchTextField.alpha = 0
            }
            
            // Restore original search state khi scroll về đầu (progress <= 0.1)
            if let originalSearchState = initialState.searchState {
                // Chỉ restore nếu state đã bị thay đổi (camera button đã bị ẩn)
                if !searchTextField.searchState.showsCameraButton && originalSearchState.showsCameraButton {
                    let restoredSearchState = EcoSearchState(
                        text: searchTextField.searchState.text, // Giữ text hiện tại
                        placeholder: originalSearchState.placeholder,
                        isEditing: searchTextField.searchState.isEditing, // Giữ editing state
                        showsClearButton: originalSearchState.showsClearButton,
                        showsCameraButton: originalSearchState.showsCameraButton, // Restore camera button
                        height: originalSearchState.height,
                        backgroundColor: originalSearchState.backgroundColor,
                        borderWidth: originalSearchState.borderWidth,
                        borderColor: originalSearchState.borderColor
                    )
                    searchTextField.apply(state: restoredSearchState)
                }
            }
        }
        
        // Update search field constraints: center with padding 16 when scrolled
        let searchPadding: CGFloat = 16
        if progress > 0.5 {
            // Center search with padding 16 on both sides
            searchFieldLeadingConstraint?.isActive = false
            searchFieldTrailingConstraint?.isActive = false
            
            if searchFieldCenterXConstraint?.isActive != true {
                searchFieldCenterXConstraint?.isActive = true
            }
            
            // Create or update width constraint for search field when centered
            if searchFieldWidthConstraint == nil {
                let searchWidth = searchTextField.widthAnchor.constraint(
                    equalTo: widthAnchor,
                    constant: -(searchPadding * 2)
                )
                searchWidth.priority = .required
                searchWidth.isActive = true
                searchFieldWidthConstraint = searchWidth
            } else {
                searchFieldWidthConstraint?.isActive = true
            }
        } else {
            // Normal layout between left and right stacks (when not scrolled)
            searchFieldCenterXConstraint?.isActive = false
            searchFieldWidthConstraint?.isActive = false
            searchFieldLeadingConstraint?.isActive = true
            searchFieldTrailingConstraint?.isActive = true
        }
        
        // Hide right stack search button when scrolling (but keep cart)
        // Hide left/right stacks when collapsed
        leftStack.alpha = 1.0 - progress
        // Hide search button in right stack when scrolling, but keep other buttons visible longer
        if progress > 0.5 {
            // Hide search button specifically (first item in right stack)
            if rightStack.arrangedSubviews.count > 0 {
                rightStack.arrangedSubviews[0].alpha = 0
                rightStack.arrangedSubviews[0].isHidden = true
            }
            // Keep other buttons visible
            if rightStack.arrangedSubviews.count > 1 {
                rightStack.arrangedSubviews[1].alpha = 1.0 - (progress * 0.5)
            }
        } else {
            // Show all right items
            rightStack.arrangedSubviews.forEach { view in
                view.alpha = 1.0 - progress
                view.isHidden = false
            }
        }
        rightStack.isHidden = progress > 0.9
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut]) {
            self.layoutIfNeeded()
        }
    }
}

// MARK: - Button Action Wrapper

private class ButtonActionWrapper: NSObject {
    let action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
        super.init()
    }
    
    @objc func execute() {
        print("🔵 [ButtonActionWrapper] execute() called - button tapped")
        action()
        print("✅ [ButtonActionWrapper] execute() completed")
    }
}

private struct AssociatedKeys {
    static var actionWrapper = "actionWrapper"
}
