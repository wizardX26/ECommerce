import UIKit

public extension UIStackView {
    func addArrangedSubviews(_ views: UIView...) {
        views.forEach {
            self.addArrangedSubview($0)
        }
    }
    
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
    }
    
    func removeArrangedSubviews() {
        removeAllArrangedSubviews()
    }
    
    func addArrangedSubviews(views: [UIView]) {
        views.forEach {
            self.addArrangedSubview($0)
        }
    }
    
    func removeAllArrangedSubviews<T: UIView>(ofType type: T.Type) {
        arrangedSubviews
            .compactMap { $0 as? T }
            .forEach { removeArrangedSubview($0) }
        
        arrangedSubviews.forEach { subview in
            NSLayoutConstraint.deactivate(subview.constraints)
            subview.removeFromSuperview()
        }
    }
}
