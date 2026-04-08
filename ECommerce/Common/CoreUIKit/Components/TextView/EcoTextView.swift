import UIKit

public enum ECoTextViewType: Int {
    case normal
    case advanced
}

public protocol ECoTextViewDelegate: AnyObject {
    func textViewShouldClear(_ textView: UITextView)
}

public extension ECoTextViewDelegate {
    func textViewShouldClear(_ textView: UITextView) {}
}

@IBDesignable
public class ECoTextView: UITextView {
    public var isContentView = false
    
    lazy var labelPlaceholder: UILabel = {
        let label = UILabel()
        return label
    }()
    
    lazy var labelCount: UILabel = {
        let label = UILabel()
        return label
    }()
    
    lazy var labelHelper: UILabel = {
        let label = UILabel()
        return label
    }()
    
    let buttonClear: UIButton = {
        let button = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: Sizing.tokenSizing24, height: Sizing.tokenSizing24))
        return button
    }()
    
    let imageViewHelper: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: Sizing.tokenSizing16, height: Sizing.tokenSizing16))
        imageView.contentMode = .scaleAspectFit
//        imageView.image = HelperFunction.getImage(named: "ic_error_16_crimsonRed100", in: Bundle(for: ECoTextField.self))
        return imageView
    }()
    
    @IBInspectable public var inputTextColor: UIColor = Colors.tokenDark100 {
        didSet {
            textColor = inputTextColor
            tintColor = inputTextColor
        }
    }
    
    @IBInspectable public var placeholderColor: UIColor = Colors.tokenDark40 {
        didSet {
            updateLabelPlaceholder()
            updateHelper()
        }
    }
    
    @IBInspectable public var titleColor: UIColor = Colors.tokenDark60 {
        didSet {
            updateLabelPlaceholder()
            updateHelper()
        }
    }
    
    @IBInspectable public var errorColor: UIColor = Colors.tokenCrimsonRed100 {
        didSet {
            updateLabelPlaceholder()
            updateHelper()
        }
    }
    
    @IBInspectable public var selectedColor: UIColor = Colors.tokenDark100 {
        didSet {
            updateLine()
        }
    }
    
    @IBInspectable public var deselectedColor: UIColor = Colors.tokenDark10 {
        didSet {
            updateLine()
        }
    }
    
    @IBInspectable public var lineHeight: CGFloat = Sizing.tokenSizing01
    
    @IBInspectable public var maxLength: Int = 150 {
        didSet {
            updateLabelCount()
        }
    }
    
    @IBInspectable public var placeholder: String? {
        didSet {
            updateLabelPlaceholder()
        }
    }
    
    @IBInspectable public var helperText: String = "" {
        didSet {
            updateLabelPlaceholder()
            updateHelper()
        }
    }
    
    @IBInspectable public var errorMessage: String = "" {
        didSet {
            updateAnimationPlaceholder()
            updateLabelPlaceholder()
            updateHelper()
        }
    }
    
    /// Type for ECoTextView
    @IBInspectable public var textViewType: Int {
        set {
            type = ECoTextViewType(rawValue: newValue) ?? .advanced
            setupTextView()
        }
        
        get {
            return type.rawValue
        }
    }
    
    public var type = ECoTextViewType.advanced
    
    public var textFont: UIFont = Typography.fontRegular18 {
        didSet {
            font = textFont
        }
    }
    
    public var titleFont: UIFont = Typography.fontRegular13 {
        didSet {
            setupTextView()
        }
    }
    
    public var placeholderFont: UIFont = Typography.fontRegular16 {
        didSet {
            setupTextView()
        }
    }
    
    @objc public var needCounting: Bool = true {
        didSet {
            updateLabelCount()
        }
    }
    
    public var isError: Bool = false {
        didSet {
            updateAnimationPlaceholder()
            updateLabelPlaceholder()
            updateHelper()
        }
    }
    public var isAllowNewLine: Bool = false
    
    public var maxHeight: CGFloat = CGFloat.greatestFiniteMagnitude
    
    private let bundle = Bundle(for: ECoTextView.self)
    
    private let helperHeight: CGFloat = Sizing.tokenSizing16
    private var defaultHeight: CGFloat = 40.0
    
    private let deselectedLayer = CALayer()
    private let selectedLayer = CALayer()
    
    private let imageClearDark = HelperFunction.getImage(named: "ic_cancel_button_16_dark40", in: Bundle(for: ECoTextView.self))
    
    private var heightConstraint: NSLayoutConstraint?
    
    @objc public var resizeFrame: ((CGRect) -> Void)?
    
    public weak var delegateCustom: ECoTextViewDelegate?
    
    public override init(frame: CGRect, textContainer: NSTextContainer? = nil) {
        super.init(frame: frame, textContainer: textContainer)
        setupTextView()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTextView()
    }
    
    public override func draw(_ rect: CGRect) {
        updateTitleIfNeed()
        updateLine()
        setupButtonClear()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        resize()
    }
    
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
        resize()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override var text: String! {
        didSet {
            updateTitleIfNeed()
            updateLabelPlaceholder()
            updateLabelCount()
        }
    }
    
    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        let success = super.becomeFirstResponder()
        if success {
            animationShowTitle()
        }
        return success
    }
    
    public func verifyTextView(shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let length = (text?.count ?? 0) + string.count - range.length
        if length > maxLength {
            return false
        }
        return true
    }
    
    private func getKeyboardLanguage() -> String? {
        return Locale.preferredLanguages.first
    }
    
    public override var textInputMode: UITextInputMode? {
        if let language = getKeyboardLanguage() {
            for tim in UITextInputMode.activeInputModes {
                if let primaryLanguage = tim.primaryLanguage, primaryLanguage.contains(language) {
                    return tim
                }
            }
        }
        return super.textInputMode
    }
}

// MARK: - Default
extension ECoTextView {
    private func setupTextView() {
        clipsToBounds = false
        backgroundColor = .clear
        textContainer.lineFragmentPadding = 0
        textContainerInset.right = Sizing.tokenSizing24
        tintColor = inputTextColor
        setupHeight()
        
        translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = heightAnchor.constraint(equalToConstant: defaultHeight)
        heightConstraint?.isActive = true
        
        resize()
        setupLayer()
        updateLine()
        setupButtonClear()
        setupLabelPlaceholder()
        setupLabelCount()
        setupLabelHelper()
        registerNotificationCenter()
    }
    
    private func setupHeight() {
        switch type {
        
        case .normal:
            defaultHeight = 25.0
            
        case .advanced:
            defaultHeight = 40.0

        }
    }
    
    private func resize() {
        var newFrame = frame
        let width = newFrame.size.width
        
        let newSize = sizeThatFits(CGSize(width: width,
                                          height: textContainer.size.height))
        newFrame.size = CGSize(width: width, height: newSize.height)
        if newSize.height > defaultHeight {
            frame = newFrame
        }
        if newSize.height < defaultHeight {
            newFrame.size = CGSize(width: width, height: defaultHeight)
            frame = newFrame
        }
        var newHeight = newFrame.height
        if maxHeight != CGFloat.greatestFiniteMagnitude && maxHeight < newHeight {
            newHeight = maxHeight
            newFrame.size = CGSize(width: width, height: newHeight)
            frame = newFrame
        }
        heightConstraint?.constant = newHeight
        
        deselectedLayer.frame = rectForLine(isFilled: !isFirstResponder)
        deselectedLayer.backgroundColor = deselectedColor.cgColor
        
        selectedLayer.frame = rectForLine(isFilled: isFirstResponder)
        selectedLayer.backgroundColor = selectedColor.cgColor
        
        if isFirstResponder {
            animationShowTitle(false)
            buttonClear.isHidden = text == ""
        } else {
            text != "" ? animationShowTitle(false) : animationHideTitle(false)
        }
        
        updateLabelCount()
        
        if let resizeFrame = resizeFrame {
            resizeFrame(newFrame)
        }
        superview?.layoutIfNeeded()
    }
    
    private func registerNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidEndEditing), name: UITextView.textDidEndEditingNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidBeginEditing), name: UITextView.textDidBeginEditingNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChange), name: UITextView.textDidChangeNotification, object: self)
    }
    
    private func textHeight() -> CGFloat {
        guard let font = font else {
            return 0.0
        }
        return font.lineHeight + Sizing.tokenSizing08
    }
    
    private func setupLayer() {
        layer.addSublayer(deselectedLayer)
        layer.addSublayer(selectedLayer)
    }
    
    private func updateTitle() {
        if isFirstResponder {
            labelPlaceholder.font = titleFont
            labelPlaceholder.textColor = hasError() ? errorColor : selectedColor
        } else {
            if hasError() {
                labelPlaceholder.font = titleFont
                return
            }
            if let text = text, !text.isEmpty {
                labelPlaceholder.font = titleFont
                labelPlaceholder.textColor = titleColor
            }
        }
    }
    
    private func setupButtonClear() {
        buttonClear.frame = CGRect(x: bounds.width - Sizing.tokenSizing24, y: Sizing.tokenSizing04, width: Sizing.tokenSizing24, height: Sizing.tokenSizing24)
        addSubview(buttonClear)
        buttonClear.setImage(imageClearDark, for: .normal)
        buttonClear.addTarget(self, action: #selector(invokeButtonClear), for: .touchUpInside)
        buttonClear.isHidden = true
    }
    
    private func setupLabelPlaceholder() {
        if isContentView {
            labelPlaceholder.frame = CGRect(x: 0.0, y: frame.size.height / 2 - 4, width: frame.width, height: textHeight())
        } else {
            labelPlaceholder.frame = CGRect(x: 0.0, y: 0.0, width: frame.width, height: textHeight())
        }
       
        insertSubview(labelPlaceholder, at: 0)
        
        labelPlaceholder.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        labelPlaceholder.text = ""
        labelPlaceholder.backgroundColor = .clear
        labelPlaceholder.textColor = placeholderColor
        labelPlaceholder.font = placeholderFont
    }
    
    public func setupLocationButtonClear() {
        buttonClear.frame = CGRect(x: bounds.width - Sizing.tokenSizing24, y: frame.size.height / 2 - Sizing.tokenSizing24 / 2 - Sizing.tokenSizing04 , width: Sizing.tokenSizing24, height: Sizing.tokenSizing24)
    }
    
    private func updateLabelPlaceholder() {
        updateTitle()
        labelPlaceholder.text = placeholder
        labelPlaceholder.font = (isFirstResponder || text != "") ? titleFont : placeholderFont
        labelPlaceholder.textColor = isFirstResponder ? selectedColor : placeholderColor
        if hasError() {
            labelPlaceholder.textColor = errorColor
        }
        
        if isContentView {
            labelPlaceholder.textColor = isFirstResponder ? Colors.tokenDark60 : Colors.tokenDark60
        }
        
    }
    
    private func setupLabelCount() {
        labelCount.frame = CGRect(x: 0.0, y: bounds.origin.y - (font?.lineHeight ?? CGFloat.zero), width: frame.width, height: textHeight())
        insertSubview(labelCount, at: 0)
        
        labelCount.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        labelCount.textAlignment = .right
        labelCount.backgroundColor = .clear
        labelCount.textColor = placeholderColor
        labelCount.font = titleFont
        updateLabelCount()
    }
    
    private func updateLabelCount() {
        labelCount.frame = CGRect(x: 0.0, y: bounds.origin.y - (font?.lineHeight ?? CGFloat.zero), width: frame.width, height: textHeight())
        if let text = text {
            labelCount.text = "\(text.count)/\(maxLength)"
        }
        labelCount.isHidden = !needCounting
    }
    
    private func updateAnimationPlaceholder() {
        if isFirstResponder {
            animationShowTitle()
        } else {
            if hasError() {
                animationShowTitle()
                return
            }
            if let text = text, text.isEmpty {
                animationHideTitle()
            }
        }
    }
    
    private func hasError() -> Bool {
        if errorMessage != "" || isError {
            return true
        }
        return false
    }
    
    private func rectForLine(isFilled: Bool) -> CGRect {
        if isFilled {
            selectedLayer.backgroundColor = hasError() ? errorColor.cgColor : selectedColor.cgColor
            return CGRect(origin: CGPoint(x: 0.0, y: bounds.size.height - lineHeight), size: CGSize(width: frame.width, height: lineHeight))
        } else {
            return CGRect(origin: CGPoint(x: 0.0, y: bounds.size.height - lineHeight), size: CGSize(width: 0.0, height: lineHeight))
        }
    }
    
    private func updateLine() {
        deselectedLayer.frame = rectForLine(isFilled: true)
        deselectedLayer.backgroundColor = deselectedColor.cgColor
        
        selectedLayer.frame = rectForLine(isFilled: false)
        selectedLayer.backgroundColor = selectedColor.cgColor
    }
    
    private func setupLabelHelper() {
        labelHelper.frame = CGRect(x: 0.0, y: bounds.height + Sizing.tokenSizing04, width: bounds.width, height: helperHeight)
        insertSubview(labelHelper, at: 0)
        updateHelper()
    }
    
    private func updateHelper() {
        updateLabelHelper()
        insertSubview(imageViewHelper, at: 0)
        imageViewHelper.frame = CGRect(x: 0.0, y: bounds.height + Sizing.tokenSizing04, width: Sizing.tokenSizing16, height: Sizing.tokenSizing16)
        imageViewHelper.isHidden = !hasError()
        labelHelper.frame = CGRect(x: Sizing.tokenSizing16 + Spacing.tokenSpacing04, y: bounds.height + Sizing.tokenSizing04, width: bounds.width, height: helperHeight)
        labelHelper.sizeToFit()
    }
    
    private func updateLabelHelper() {
        updateTitle()
        labelHelper.text = helperText
        labelHelper.font = titleFont
        labelHelper.textColor = isFirstResponder ? selectedColor : placeholderColor
        if hasError() {
            selectedLayer.frame = rectForLine(isFilled: true)
            labelHelper.text = errorMessage != "" ? errorMessage : helperText
            labelHelper.textColor = errorColor
        } else {
            labelHelper.text = helperText
            labelHelper.numberOfLines = 2
        }
    }
    
    private func animationShowTitle(_ animated: Bool = true) {
        UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
            if self.isContentView {
                self.labelPlaceholder.frame = CGRect(x: 0.0,
                                                     y: self.bounds.origin.y - (self.font?.lineHeight ?? CGFloat.zero),
                                                     width: self.bounds.width,
                                                     height: self.textHeight())
            } else {
                self.labelPlaceholder.frame = CGRect(x: 0.0,
                                                     y: self.bounds.origin.y - (self.font?.lineHeight ?? CGFloat.zero),
                                                     width: self.bounds.width,
                                                     height: self.textHeight())
            }
         
            self.updateLabelPlaceholder()
        })
    }
    
    private func animationHideTitle(_ animated: Bool = true) {
        if isContentView {
            UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
                self.labelPlaceholder.frame = CGRect(x: 0.0, y: self.bounds.origin.y, width: self.bounds.width, height: self.textHeight())
                self.updateLabelPlaceholder()
            })
        } else {
            UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
                self.labelPlaceholder.frame = CGRect(x: 0.0, y: self.bounds.origin.y, width: self.bounds.width, height: self.textHeight())
                self.updateLabelPlaceholder()
            })
        }
        
    }
    
    private func updateTitleIfNeed() {
        updateTitle()
        if let text = text {
            text.isEmpty ? animationHideTitle(false) : animationShowTitle(false)
        } else {
            animationHideTitle(false)
        }
    }
    
    @objc
    private func textViewDidBeginEditing() {
        if let text = text, text != "" {
            buttonClear.isHidden = false
        } else {
            buttonClear.isHidden = true
        }
        selectedLayer.frame = rectForLine(isFilled: true)
        updateAnimationPlaceholder()
        updateTitle()
        updateLabelHelper()
        if isFirstResponder {
            animationShowTitle()
        } else {
            if hasError() {
                animationShowTitle()
                return
            }
            if let text = text, text.isEmpty {
                animationHideTitle()
            }
            animationHideTitle()
        }
        labelPlaceholder.textColor = Colors.tokenDark60
    }
    
    @objc
    private func textViewDidEndEditing() {
        buttonClear.isHidden = true
        selectedLayer.frame = rectForLine(isFilled: false)
        updateAnimationPlaceholder()
        updateTitle()
        updateLabelHelper()
    }
    
    @objc
    private func textViewDidChange() {
        if let text = text, text != "" {
            buttonClear.isHidden = false
        } else {
            buttonClear.isHidden = true
        }
        if isAllowNewLine {
            text = text.replacingOccurrences(of: "\n\n", with: "\n")
        } else {
            text = text.replacingOccurrences(of: "\n", with: "")
        }
        errorMessage = ""
        isError = false
        resize()
        animationShowTitle()
        updateTitle()
        updateLabelCount()
        deselectedLayer.frame = rectForLine(isFilled: true)
        selectedLayer.frame = rectForLine(isFilled: true)
    }
    
    @objc
    private func invokeButtonClear() {
        buttonClear.isHidden = true
        text = ""
        errorMessage = ""
        isError = false
        resize()
        updateAnimationPlaceholder()
        updateLabelPlaceholder()
        updateTitle()
        updateLabelCount()
        updateHelper()
        deselectedLayer.frame = rectForLine(isFilled: true)
        selectedLayer.frame = rectForLine(isFilled: isFirstResponder)
        delegateCustom?.textViewShouldClear(self)
    }
}
