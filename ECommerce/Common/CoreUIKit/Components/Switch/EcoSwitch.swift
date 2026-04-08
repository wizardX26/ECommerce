import UIKit

@IBDesignable
public class ECoSwitch: UISwitch {
    let scale: CGFloat = 0.75
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpCustomUserInterface()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpCustomUserInterface()
    }

    func setUpCustomUserInterface() {
        // Clip the background color
        layer.cornerRadius = Sizing.tokenSizing16
        layer.masksToBounds = true
        
        // Scale down to make it smaller in look
        transform = CGAffineTransform(scaleX: scale, y: scale)

        // Add target to get user interation to update user-interface accordingly
        addTarget(self, action: #selector(updateUI), for: UIControl.Event.valueChanged)

        // Set onTintColor : is necessary to make it colored
        onTintColor = Colors.tokenSpaceBlue20

        // Setup to initial state
        updateUI()
    }

    // To track programatic update
    public override func setOn(_ isOn: Bool, animated: Bool) {
        super.setOn(isOn, animated: true)
        updateUI()
    }

    // Update user-interface according to on/off state
    @objc
    func updateUI() {
        if #available(iOS 14, *) {
            if isOn {
                thumbTintColor = Colors.tokenSpaceBlue100
                backgroundColor = Colors.tokenSpaceBlue20
            } else {
                thumbTintColor = Colors.tokenWhite
                backgroundColor = Colors.tokenDark40
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.15) {
                if self.isOn {
                    self.thumbTintColor = Colors.tokenSpaceBlue100
                    self.backgroundColor = Colors.tokenSpaceBlue20
                } else {
                    self.thumbTintColor = Colors.tokenWhite
                    self.backgroundColor = Colors.tokenDark40
                }
            }
        }
    }
}
