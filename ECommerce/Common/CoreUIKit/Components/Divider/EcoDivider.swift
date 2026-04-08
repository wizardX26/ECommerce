import UIKit

public enum DividerType: Int {
    case small
    case large
    
    func getDividerSize() -> CGFloat {
        switch self {
        case .small:
            return Sizing.tokenSizing01
        case .large:
            return Sizing.tokenSizing08
        }
    }
}

@IBDesignable
public class ECoDivider: UIView {
    
    private var sizeConstraint: NSLayoutConstraint?
    
    public var dividerType: DividerType = .small {
        didSet {
            remakeSize()
        }
    }
    
    public var isVertical: Bool = false {
        didSet {
            remakeSize()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
}

extension ECoDivider {
    
    private func commonInit() {
        setupSize()
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = Colors.tokenDark10
    }
    
    private func setupSize() {
        sizeConstraint = heightAnchor.constraint(equalToConstant: dividerType.getDividerSize())
        sizeConstraint?.isActive = true
    }
    
    private func remakeSize() {
        sizeConstraint?.isActive = false
        
        let size = dividerType.getDividerSize()
        if isVertical {
            sizeConstraint = widthAnchor.constraint(equalToConstant: size)
        } else {
            sizeConstraint = heightAnchor.constraint(equalToConstant: size)
        }
        sizeConstraint?.isActive = true
    }
}
