//
//  LanguageSwitcher.swift
//  ECommerce
//
//  Created for localization support.
//

import UIKit

/// Presents language picker (EN/VI) and applies change. On apply, posts `LanguageChangeNotification`;
/// AppDelegate should observe and call `splashCoordinatingController?.start()` to reload the app.
enum LanguageSwitcher {

    static func presentAndApply() {
        guard let top = topViewController() else { return }
        present(from: top)
    }

    private static func present(from presenter: UIViewController) {
        let sheet = UIAlertController(
            title: "language".localized(),
            message: nil,
            preferredStyle: .actionSheet
        )
        let en = UIAlertAction(title: "English", style: .default) { _ in
            applyLanguage("en")
        }
        let vi = UIAlertAction(title: "Tiếng Việt", style: .default) { _ in
            applyLanguage("vi")
        }
        let cancel = UIAlertAction(title: "cancel".localized(), style: .cancel)
        sheet.addAction(en)
        sheet.addAction(vi)
        sheet.addAction(cancel)

        if let popover = sheet.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        presenter.present(sheet, animated: true)
    }

    private static func applyLanguage(_ code: String) {
        print("🌐 [LanguageSwitcher] Applying language: \(code)")
        let previousLanguage = Localize.currentLanguage()
        Localize.setCurrentLanguage(code)
        let newLanguage = Localize.currentLanguage()
        print("🌐 [LanguageSwitcher] Language changed from \(previousLanguage) to \(newLanguage)")
        // Notification will be posted by Localize.setCurrentLanguage
        // AppDelegate will observe and reload the app
    }

    /// Button title for the right bar: show the *other* language to suggest "Switch to EN" / "Switch to VI".
    static func barButtonTitle() -> String {
        Localize.currentLanguage() == "vi" ? "EN" : "VI"
    }

    private static func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else { return nil }
        var vc = window.rootViewController
        while let presented = vc?.presentedViewController { vc = presented }
        if let nav = vc as? UINavigationController { return nav.topViewController ?? nav }
        return vc
    }
}
