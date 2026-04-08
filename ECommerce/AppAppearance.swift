import UIKit

final class AppAppearance {

    static func setupAppearance() {
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.backgroundColor = UIColor(
                red: 37/255.0,
                green: 37/255.0,
                blue: 37/255.0,
                alpha: 1.0
            )
            
            let navBar = UINavigationBar.appearance()
            navBar.standardAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
        } else {
            let navBar = UINavigationBar.appearance()
            navBar.barTintColor = .black
            navBar.tintColor = .white
            navBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
    }
}

extension UINavigationController {
    @objc override open var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}
