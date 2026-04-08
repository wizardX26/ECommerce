//import UIKit
//
///// tiny size: 32x32
///// smail size: 40x40
///// medium size:  56x56
///// large size: 64x64
//public enum AvatarViewSize: Int {
//    case size32
//    case size36
//    case size40
//    case size48
//    case size56
//    case size64
//    case size28
//    case size58
//    case size76
//}
//
//public enum AvatarViewType: Int {
//    case normal
//    case voucher
//}
//
//@objc
//public protocol ECoAvatarViewDelegate: NSObjectProtocol {
//    @objc
//    optional func avatarView(_ avatarView: ECoAvatarView, longPress sender: UILongPressGestureRecognizer)
//}
//
//@IBDesignable
//open class ECoAvatarView : ECoCardView {
//    // MARK: Constant
//    let charColorList = [Colors.tokenCrimsonRed100, Colors.tokenGold100, Colors.tokenPineBlue100, Colors.tokenSpaceBlue100, Colors.tokenViettelPayRed100]
//
//    let bundle = Bundle(for: ECoAvatarView.self)
//
//    // MARK: View
//    var imageView: UIImageView = {
//        let view = UIImageView()
//        view.contentMode = .scaleAspectFill
//
//        return view
//    }()
//
//    var label = UILabel()
//
//    // MARK: Constraint
//    private lazy var avatarHeightConstraint : NSLayoutConstraint = {
//        let constraint = heightAnchor.constraint(equalToConstant: Sizing.tokenSizing32)
//        constraint.isActive = true
//        return constraint
//    }()
//    
//    private var imageViewWidthConstraint: NSLayoutConstraint?
//    private var imageViewHeightConstraint: NSLayoutConstraint?
//    private var imageViewCenterXConstraint: NSLayoutConstraint?
//
//    // MARK: Variable
//    public var defaultImage : UIImage? = HelperFunction.getImage(named: "avatar_default_64", in: Bundle(for: ECoAvatarView.self))
//
//    /// Size of avatar
//    @IBInspectable public var size: Int = AvatarViewSize.size56.rawValue {
//        didSet {
//            setSize()
//        }
//    }
//
//    /// Type of avatar
//    @IBInspectable public var type: Int = AvatarViewType.normal.rawValue {
//        didSet {
//            setType()
//        }
//    }
//
//    /// Name: use first name, will be truncated to use first character of first name. E.g: God -> G
//    @IBInspectable var name: String = "" {
//        didSet {
//            label.text = getFirstCharacterFromString(name)
//            label.textColor = getTextColorFromString(label.text ?? "")
//            label.font = getFontSizeFromViewWidth()
//            label.isHidden = false
//            imageView.isHidden = true
//        }
//    }
//    
//    @IBInspectable var customName: String = "" {
//        didSet {
//            label.text = getFirstCharacterFromLastWords(customName)
//            label.textColor = getTextColorFromString(label.text ?? "")
//            label.font = Typography.fontBold24
//            label.isHidden = false
//            imageView.isHidden = true
//        }
//    }
//
//    /// Avatar image
//    @IBInspectable var image: UIImage? {
//        didSet {
//            imageView.image = image
//
//            label.isHidden = true
//            imageView.isHidden = false
//        }
//    }
//
//    /// Optional style: border color
//    @IBInspectable public var borderColor : UIColor = Colors.tokenDark10 {
//        didSet {
//            normalState()
//        }
//    }
//
//    /// Optional style: selected border color
//    @IBInspectable public var selectedBorderColor : UIColor = Colors.tokenViettelPayRed100
//
//    /// Optional style: border width
//    @IBInspectable public var borderWidth: CGFloat = 1 {
//        didSet {
//            layer.borderWidth = borderWidth
//        }
//    }
//    /// State indicates long press should be handled or not
//    @IBInspectable public var isEnabled: Bool = true
//
//    public var avatarContentMode: ContentMode = .scaleAspectFill {
//        didSet {
//            imageView.contentMode = avatarContentMode
//        }
//    }
//
//    public weak var delegate: ECoAvatarViewDelegate?
//
//    public var paddingImage: CGFloat = 0 {
//        didSet {
//            imageView.layer.cornerRadius = avatarHeightConstraint.constant / 2 - paddingImage
//            imageViewWidthConstraint?.constant = -paddingImage * 2
//        }
//    }
//
//    var isUsingDefaultImage = true
//    // MARK: Init
//    public override init(frame: CGRect) {
//        super.init(frame: frame)
//        avatarCommonInit()
//        widthAnchor.constraint(equalTo: heightAnchor).isActive = true
//    }
//
//    required public init?(coder: NSCoder) {
//        super.init(coder: coder)
//        avatarCommonInit()
//        widthAnchor.constraint(equalTo: heightAnchor).isActive = true
//    }
//
//    private func avatarCommonInit() {
//        backgroundColor = .white
//        imageView.backgroundColor = .white
//        label.backgroundColor = .white
//
//        setType()
//        // Setup border
//        layer.masksToBounds = true
//        clipsToBounds = true
//        normalState()
//        layer.borderWidth = borderWidth
//
//        // Setup image view
//        addSubview(imageView)
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        
//        imageViewWidthConstraint = imageView.widthAnchor.constraint(equalTo: widthAnchor, constant: -paddingImage * 2)
//        imageViewHeightConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
//        imageViewCenterXConstraint = imageView.centerXAnchor.constraint(equalTo: centerXAnchor)
//        
//        NSLayoutConstraint.activate([
//            imageViewWidthConstraint!,
//            imageViewHeightConstraint!,
//            imageViewCenterXConstraint!
//        ])
//        
//        imageView.layer.borderWidth = 0
//        imageView.layer.masksToBounds = true
//        imageView.layer.cornerRadius = CGFloat(size) / 2 - paddingImage
//        imageView.isHidden = true
//        imageView.backgroundColor = .clear
//
//        // Setup label
//        addSubview(label)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            label.leadingAnchor.constraint(equalTo: leadingAnchor),
//            label.trailingAnchor.constraint(equalTo: trailingAnchor),
//            label.topAnchor.constraint(equalTo: topAnchor),
//            label.bottomAnchor.constraint(equalTo: bottomAnchor)
//        ])
//        label.textAlignment = .center
//        label.isHidden = true
//        label.backgroundColor = .clear
//
//        // Setup long press
//        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
//        lpgr.minimumPressDuration = 0
//        lpgr.delaysTouchesBegan = true
//        addGestureRecognizer(lpgr)
//
//        // Change view setting
//        translatesAutoresizingMaskIntoConstraints = false
//
//        setSize()
//
//        // Set default image
//        setData(image: nil, name: nil)
//    }
//
//    // MARK: Setter
//    private func setSize() {
//        switch size {
//        case AvatarViewSize.size32.rawValue:
//            avatarHeightConstraint.constant = Sizing.tokenSizing32
//        case AvatarViewSize.size36.rawValue:
//            avatarHeightConstraint.constant = Sizing.tokenSizing36
//        case AvatarViewSize.size40.rawValue:
//            avatarHeightConstraint.constant = Sizing.tokenSizing40
//        case AvatarViewSize.size48.rawValue:
//            avatarHeightConstraint.constant = Sizing.tokenSizing48
//        case AvatarViewSize.size56.rawValue:
//            avatarHeightConstraint.constant = Sizing.tokenSizing56
//        case AvatarViewSize.size64.rawValue:
//            avatarHeightConstraint.constant = Sizing.tokenSizing64
//        case AvatarViewSize.size28.rawValue:
//            avatarHeightConstraint.constant = Sizing.tokenSizing28
//        case AvatarViewSize.size58.rawValue:
//            avatarHeightConstraint.constant = 58.0
//        case AvatarViewSize.size76.rawValue:
//            avatarHeightConstraint.constant = 76.0
//        default:
//            avatarHeightConstraint.constant = Sizing.tokenSizing40
//        }
//        cornerRadius = avatarHeightConstraint.constant / 2
//        imageView.layer.cornerRadius = avatarHeightConstraint.constant / 2 - paddingImage
//        imageViewWidthConstraint?.constant = -paddingImage * 2
//    }
//
//    private func setType() {
//        switch type {
//        case AvatarViewType.normal.rawValue:
//            shadowHidden = true
//        case AvatarViewType.voucher.rawValue:
//            shadowHidden = false
//        default:
//            shadowHidden = false
//        }
//    }
//
//    public func reloadAvatarImage() {
//        self.imageView.image = nil
//        self.imageView.isHidden = true
//    }
//
//    /// Set default image,
//    /// - Parameter image: new default image
//    public func setDefaultImage(image: UIImage) {
//        defaultImage = image
//        if isUsingDefaultImage {
//            self.image = defaultImage
//        } else {
//            self.image = nil
//        }
//    }
//    
//    /// Set `AvatarView` data with priority: image > name > default image
//    /// - Parameters:
//    ///   - image: avatar 's image
//    ///   - name: avatar 's name
//    public func setData(image: UIImage?, name: String?) {
//        if image != nil {
//            isUsingDefaultImage = false
//            self.image = image
//        } else if name != nil {
//            isUsingDefaultImage = false
//            self.image = nil
//            self.name = name!
//        } else {
//            isUsingDefaultImage = true
//            self.image = defaultImage
//        }
//    }
//    
//    /// Set `AvatarView` data with priority: image > name > default image
//    /// - Parameters:
//    ///   - urlString: avatar 's image url
//    ///   - name: avatar 's name
//    public func setData(urlString: String?, name: String?) {
//        if urlString != nil {
//            imageView.isHidden = true
//            self.setData(image: nil, name: name)
//            imageView.load(urlString: urlString!, completion: { [weak self] (_, image) in
//                self?.setData(image: image, name: name)
//            })
//        } else if name != nil {
//            isUsingDefaultImage = false
//            self.image = nil
//            self.name = name!
//        } else {
//            isUsingDefaultImage = true
//            self.image = defaultImage
//        }
//    }
//    
//    @objc
//    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
//        if !isEnabled {
//            return
//        }
//        if gestureReconizer.state != UIGestureRecognizer.State.ended {
//            // When longpress is start or running
//            selectedState()
//        } else {
//            // When longpress is finish
//            normalState()
//        }
//        guard let delegate = delegate else {
//            return
//        }
//        delegate.avatarView?(self, longPress: gestureReconizer)
//    }
//    
//    // MARK: Helper
//    public override func layoutSubviews() {
//        super.layoutSubviews()
//        if !label.isHidden {
//            label.center = convert(center, from:superview)
//        }
//        if !imageView.isHidden {
//            imageView.center = convert(center, from:superview)
//        }
//    }
//    
//    private func getFontSizeFromViewWidth() -> UIFont {
//        var font = Typography.fontBold16
//        switch Int(bounds.width) {
//        case 0...32:
//            font = Typography.fontBold16
//        case 33...40:
//            font = Typography.fontBold18
//        default:
//            font = Typography.fontBold24
//        }
//        
//        return font
//    }
//    
//    private func getFirstCharacterFromString(_ string: String) -> String {
//        var normalizedString = string.removeDiacritics()
//        normalizedString = normalizedString.uppercased()
//        if let first = normalizedString.first {
//            return "\(first)"
//        } else {
//            return ""
//        }
//    }
//    
//    private func getTextColorFromString(_ string: String) -> UIColor {
//        let output = string.withoutSpecialCharacters
//        let numberOrderOfChar = (Int(UInt32(Unicode.Scalar(output)?.value ?? 0)))
//        return charColorList[numberOrderOfChar % 5]
//    }
//    
//    public func selectedState() {
//        layer.borderColor = selectedBorderColor.cgColor
//    }
//    
//    public func normalState() {
//        layer.borderColor = borderColor.cgColor
//    }
//}
//
//extension ECoAvatarView {
//    
//    public func customSetData(urlString: String?, name: String?) {
//        if let urlString = urlString, !urlString.isEmpty {
//            imageView.isHidden = true
//            self.customSetData(image: nil, name: name)
//            imageView.load(urlString: urlString, completion: { [weak self] (_, image) in
//                self?.customSetData(image: image, name: name)
//            })
//        } else if let name = name, !name.isEmpty {
//            isUsingDefaultImage = false
//            self.image = nil
//            self.customName = name
//        } else {
//            isUsingDefaultImage = true
//            self.image = defaultImage
//        }
//    }
//    
//    public func setImageWithURL(urlString: String?, placeholder: String?) {
//        if let url = URL(string: urlString ?? "") {
//            imageView.isHidden = false
//            label.text = ""
//            defaultImage = HelperFunction.getImage(named: "avatar_default_64", in: Bundle(for: ECoAvatarView.self))
//            let image = (placeholder?.isEmpty ?? true) ? defaultImage : UIImage(named: placeholder ?? "")
//            //imageView.sd_setImage(with: url, placeholderImage: image)
//        }
//    }
//    
//    public func customSetData(image: UIImage?, name: String?) {
//        if image != nil {
//            isUsingDefaultImage = false
//            self.image = image
//        } else if let name = name, !name.isEmpty {
//            isUsingDefaultImage = false
//            self.image = nil
//            self.customName = name
//        } else {
//            isUsingDefaultImage = true
//            defaultImage = HelperFunction.getImage(named: "avatar_default_64", in: Bundle(for: ECoAvatarView.self))
//            self.image = defaultImage
//        }
//    }
//
//    private func getFirstCharacterFromLastWords(_ string: String) -> String {
//        let components = string.components(separatedBy: " ")
//        if let lastComponent = components.last {
//            if let firstCharacter = lastComponent.first {
//                if firstCharacter.isNumber {
//                    return String(firstCharacter) // Trả về số đầu tiên nếu là số
//                } else {
//                    return String(firstCharacter).uppercased() // Trả về chữ cái đầu tiên nếu là chữ
//                }
//            }
//        }
//        return ""
//    }
//}
