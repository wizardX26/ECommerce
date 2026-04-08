import UIKit

public protocol KeyboardHandler: AnyObject {
    var bottomKeyboardConstraint: NSLayoutConstraint! { get set }
    func keyboardWillShow(_ notification: Foundation.Notification)
    func keyboardWillHide(_ notification: Foundation.Notification)
    func startObservingKeyboardChanges()
    func stopObservingKeyboardChanges()
}

public extension KeyboardHandler where Self: UIViewController {
    
    var tabBarHeight: CGFloat {
        if tabBarController?.tabBar.isHidden ?? true {
            return 0
        }
        return tabBarController?.tabBar.bounds.size.height ?? 0
    }
    
    func startObservingKeyboardChanges() { // swiftlint:disable line_length
        // NotificationCenter observers
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] notification in // swiftlint:disable:this discarded_notification_center_observer
            self?.keyboardWillShow(notification)
        }
        
        // Deal with rotations
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: nil) { [weak self] notification in // swiftlint:disable:this discarded_notification_center_observer
            self?.keyboardWillShow(notification)
        }
        
        // Deal with keyboard change (emoji, numerical, etc.)
        NotificationCenter.default.addObserver(forName: UITextInputMode.currentInputModeDidChangeNotification, object: nil, queue: nil) { [weak self] notification in // swiftlint:disable:this discarded_notification_center_observer
            self?.keyboardWillShow(notification)
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] notification in // swiftlint:disable:this discarded_notification_center_observer
            self?.keyboardWillHide(notification)
        }
    }
    
    func keyboardWillShow(_ notification: Foundation.Notification) {
        // Padding between the bottom of the view and the top of the keyboard
        var verticalPadding: CGFloat = 0
        
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            let bottomPadding = window?.safeAreaInsets.bottom
            
            if let tabBarCont = tabBarController {
                if tabBarCont.tabBar.isHidden == true {
                    verticalPadding = -bottomPadding!
                } else {
                    verticalPadding = -tabBarCont.tabBar.bounds.size.height
                }
            } else {
                verticalPadding = -bottomPadding!
            }
        } else {
            
        }
        
        guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        let keyboardHeight = value.cgRectValue.height
        
        // Here you could have more complex rules, like checking if the textField currently selected is a12ctually covered by the keyboard, but that's out of this scope.
        self.bottomKeyboardConstraint.constant = keyboardHeight + verticalPadding
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func keyboardWillHide(_ notification: Foundation.Notification) {
        self.bottomKeyboardConstraint.constant = 0
//
//        UIView.animate(withDuration: 0.1, animations: { () -> Void in
//            self.view.layoutIfNeeded()
//        })
    }
    
    func stopObservingKeyboardChanges() {
        NotificationCenter.default.removeObserver(self)
    }
    
}
