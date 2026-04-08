import UIKit

@objc
public protocol RadioButtonStateDelegate: NSObjectProtocol {
    func onRadioButtonStateChange(_ sender: UIView)
}

@IBDesignable
public class ECoRadioButton: UIView {
    
    private let radioSize = Sizing.tokenSizing24
    private let bundle = Bundle(for: ECoRadioButton.self)
    
    private lazy var radioImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.translatesAutoresizingMaskIntoConstraints = false
        return imgView
    }()

    private var radioLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var button: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.titleLabel?.text = ""
        btn.addTarget(self, action: #selector(onRadioButtonStateChange(_:)), for: .touchUpInside)
        return btn
    }()
    
    // Constraints for dynamic updates
    private var radioImageViewConstraints: [NSLayoutConstraint] = []
    private var radioLabelConstraints: [NSLayoutConstraint] = []
    
    public weak var delegate: RadioButtonStateDelegate?
    
    public var isAnimationSelect = true
    
    public var isSelected: Bool = false {
        didSet {
            changeRadioState()
        }
    }
    
    public var isLeft: Bool = true {
        didSet {
            setupLayout()
        }
    }
    
    public var textFont: UIFont? {
        didSet {
            radioLabel.font = textFont
        }
    }
    
    public var textAlpha: CGFloat? {
        didSet {
            radioLabel.alpha = textAlpha ?? 1.0
        }
    }
    
    @IBInspectable public var radioTitle: String = "Title" {
        didSet {
            updateTitle()
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

extension ECoRadioButton {
    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        setup()
        setupLayout()
    }
    
    private func setup() {
        addSubview(radioImageView)
        addSubview(radioLabel)
        addSubview(button)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    private func setupLayout() {
        // Remove old constraints
        NSLayoutConstraint.deactivate(radioImageViewConstraints)
        NSLayoutConstraint.deactivate(radioLabelConstraints)
        radioImageViewConstraints.removeAll()
        radioLabelConstraints.removeAll()
        
        // Radio Image - common constraints
        radioImageViewConstraints.append(contentsOf: [
            radioImageView.widthAnchor.constraint(equalToConstant: radioSize),
            radioImageView.heightAnchor.constraint(equalToConstant: radioSize),
            radioImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        radioImageView.image = HelperFunction.getImage(named: "ic_radio_uncheck", in: bundle)
        
        // Radio Label - common constraints
        radioLabelConstraints.append(contentsOf: [
            radioLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: Spacing.tokenSpacing08),
            radioLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -Spacing.tokenSpacing08),
            radioLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        radioLabel.font = Typography.fontRegular14
        radioLabel.numberOfLines = 0
        
        configLayouts()
    }
    
    private func configLayouts() {
        if isLeft {
            radioImageViewConstraints.append(contentsOf: [
                radioImageView.leadingAnchor.constraint(equalTo: leadingAnchor)
            ])
            radioLabelConstraints.append(contentsOf: [
                radioLabel.leadingAnchor.constraint(equalTo: radioImageView.trailingAnchor, constant: Spacing.tokenSpacing08),
                radioLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.tokenSpacing08)
            ])
        } else {
            radioImageViewConstraints.append(contentsOf: [
                radioImageView.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
            radioLabelConstraints.append(contentsOf: [
                radioLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.tokenSpacing08),
                radioLabel.trailingAnchor.constraint(equalTo: radioImageView.leadingAnchor, constant: -Spacing.tokenSpacing08)
            ])
        }
        
        NSLayoutConstraint.activate(radioImageViewConstraints)
        NSLayoutConstraint.activate(radioLabelConstraints)
    }
    
    private func changeRadioState() {
        if isSelected {
            radioImageView.setImage(HelperFunction.getImage(named: "ic_radio_check", in: bundle), animated: self.isAnimationSelect)
        } else {
            radioImageView.image = HelperFunction.getImage(named: "ic_radio_uncheck", in: bundle)
        }
    }
    
    private func updateTitle() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Spacing.tokenSpacing08
        let attrString = NSMutableAttributedString(string: radioTitle)
        attrString.addAttribute(.paragraphStyle, value:paragraphStyle, range: NSRange(location: 0, length: attrString.length))
        radioLabel.attributedText = attrString
    }
}

extension ECoRadioButton: RadioButtonStateDelegate {
    @objc
    public func onRadioButtonStateChange(_ sender: UIView) {
        if isSelected {
            return
        }
        delegate?.onRadioButtonStateChange(self)
    }
}
