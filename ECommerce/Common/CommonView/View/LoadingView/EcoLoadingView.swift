import UIKit

class EcoLoadingView {

    internal static var spinner: UIActivityIndicatorView?

    static func show() {
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(update),
                name: UIDevice.orientationDidChangeNotification,
                object: nil
            )
            
            guard spinner == nil else { return }
            
            // Get window using modern API (iOS 13+)
            let window: UIWindow?
            if #available(iOS 13.0, *) {
                window = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }
            } else {
                window = UIApplication.shared.keyWindow
            }
            
            guard let window = window else { return }
            
            let frame = UIScreen.main.bounds
            let spinner = UIActivityIndicatorView(frame: frame)
            spinner.backgroundColor = UIColor.black.withAlphaComponent(0.2)
            spinner.style = UIActivityIndicatorView.Style.large
            window.addSubview(spinner)

            spinner.startAnimating()
            self.spinner = spinner
        }
    }

    static func hide() {
        DispatchQueue.main.async {
            guard let spinner = spinner else { return }
            spinner.stopAnimating()
            spinner.removeFromSuperview()
            self.spinner = nil
            NotificationCenter.default.removeObserver(self)
        }
    }

    @objc static func update() {
        DispatchQueue.main.async {
            if spinner != nil {
                hide()
                show()
            }
        }
    }
}
