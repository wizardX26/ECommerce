import UIKit

@IBDesignable
public class ECoProgressView: UIView {
    
    private var ringWidth = Sizing.tokenSizing16
    
    let backgroundMask = CAShapeLayer()
    let progressLayer = CAShapeLayer()
    
    private var duration: CFTimeInterval = 0
    
    public var progress: CGFloat = 0 {
        didSet {
            if progress <= 0.3 {
                duration = 0.5
            } else if progress > 0.3 && progress <= 0.6 {
                duration = 1.0
            } else {
                duration = 1.5
            }
            setNeedsDisplay()
        }
    }
    
    private var progressColor = Colors.tokenDark10.cgColor
    private var progressFull = Colors.tokenDark10.cgColor
    
    public override func draw(_ rect: CGRect) {
        let circlePath = UIBezierPath(ovalIn: rect.insetBy(dx: ringWidth / 2, dy: ringWidth / 2))
        backgroundMask.path = circlePath.cgPath
        
        progressLayer.path = circlePath.cgPath
        progressLayer.strokeStart = 0
        progressLayer.strokeEnd = progress
        progressLayer.lineCap = .round
        if progress < 1 {
            progressLayer.strokeColor = progressColor
        } else {
            progressLayer.strokeColor = progressFull
        }
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        animation.fromValue = 0
        animation.toValue = progress
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        progressLayer.add(animation, forKey: "animation")
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

extension ECoProgressView {
    private func commonInit() {
        configSize()
        setupLayer()
    }
    
    private func setupLayer() {
        backgroundMask.lineWidth = ringWidth
        backgroundMask.fillColor = nil
        backgroundMask.strokeColor = Colors.tokenRainbowRedEnd.cgColor
        layer.mask = backgroundMask
        layer.addSublayer(backgroundMask)
        
        progressLayer.lineWidth = ringWidth
        progressLayer.fillColor = nil
        layer.addSublayer(progressLayer)
        layer.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, -1)
    }
    
    private func configSize() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0 / 1.0).isActive = true
    }
}
