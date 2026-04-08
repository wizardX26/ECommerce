import UIKit

//
//  UITableView+Register.swift
//  CoreUtilsKit
//
//  Created by ChatGPT
//

import UIKit

extension UITableViewCell: NibLoadableView {}
extension UITableViewHeaderFooterView: NibLoadableView {}


// MARK: - UITableView Register Support
public extension UITableView {

    /// Đăng ký cell, tự nhận diện code-only hay xib
    func register<T: UITableViewCell>(cell: T.Type) {
        let nibExists = Bundle(for: T.self)
            .path(forResource: T.reuseIdentifier, ofType: "nib") != nil

        if nibExists {
            register(T.nib, forCellReuseIdentifier: T.reuseIdentifier)
        } else {
            register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
        }
    }

    /// Đăng ký header/footer, auto detect xib
    func register<T: UITableViewHeaderFooterView>(headerFooter: T.Type) {
        let nibExists = Bundle(for: T.self)
            .path(forResource: T.reuseIdentifier, ofType: "nib") != nil

        if nibExists {
            register(T.nib, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
        } else {
            register(T.self, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
        }
    }
}


// MARK: - UITableView Dequeue Support
public extension UITableView {

    /// Dequeue cell type-safe
    func dequeueReusableCell<T: UITableViewCell>(
        ofType cellType: T.Type = T.self,
        at indexPath: IndexPath
    ) -> T {
        guard let cell = dequeueReusableCell(
            withIdentifier: cellType.reuseIdentifier,
            for: indexPath
        ) as? T else {
            fatalError("❌ Could not dequeue cell: \(cellType.reuseIdentifier)")
        }
        return cell
    }

    /// Dequeue header/footer type-safe
    func dequeueReusableHeaderFooter<T: UITableViewHeaderFooterView>(
        ofType type: T.Type = T.self
    ) -> T {
        guard let view = dequeueReusableHeaderFooterView(
            withIdentifier: type.reuseIdentifier
        ) as? T else {
            fatalError("❌ Could not dequeue header/footer: \(type.reuseIdentifier)")
        }
        return view
    }
}

//--------------
extension UITableViewController {

    func makeActivityIndicator(size: CGSize) -> UIActivityIndicatorView {
        let style: UIActivityIndicatorView.Style
        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark {
                style = .medium
            } else {
                style = .medium
            }
        } else {
            style = .medium
        }

        let activityIndicator = UIActivityIndicatorView(style: style)
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        activityIndicator.frame = .init(origin: .zero, size: size)

        return activityIndicator
    }
}
