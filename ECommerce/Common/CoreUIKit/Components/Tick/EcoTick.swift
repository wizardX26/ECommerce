import UIKit

@IBDesignable
public class ECoTick: UIImageView {
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    
    public var size = Sizing.tokenSizing24 {
        didSet {
            widthConstraint?.constant = size
        }
    }
    
    private let bundle = Bundle(for: ECoTick.self)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        
        widthConstraint = widthAnchor.constraint(equalToConstant: size)
        heightConstraint = heightAnchor.constraint(equalTo: widthAnchor)
        
        NSLayoutConstraint.activate([
            widthConstraint!,
            heightConstraint!
        ])
        
        image = HelperFunction.getImage(named: "ic_tick_24_vtpRed100", in: bundle)
    }
}


public class ECoNewTick: UIView {
    private let imageView = UIImageView()
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    
    public var isSelected: Bool = false {
        didSet {
            let bundle = Bundle(for: ECoTick.self)
            let name = isSelected ? "ic_new_tick" : "ic_new_tick_not_select"
            imageView.image = HelperFunction.getImage(named: name, in: bundle)
        }
    }
    
    public var size = Sizing.tokenSizing24 {
        didSet {
            widthConstraint?.constant = size
            heightConstraint?.constant = size
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        isUserInteractionEnabled = true
        
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        translatesAutoresizingMaskIntoConstraints = false
        widthConstraint = widthAnchor.constraint(equalToConstant: size)
        heightConstraint = heightAnchor.constraint(equalToConstant: size)
        
        NSLayoutConstraint.activate([
            widthConstraint!,
            heightConstraint!
        ])
        
        isSelected = false
    }
}
