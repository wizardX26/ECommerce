//
//  UIView+Reuseable.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

// MARK: - ReusableView (reuseIdentifier auto-gen)
public protocol ReusableView: AnyObject {
    static var reuseIdentifier: String { get }
}

public extension ReusableView {
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}

// MARK: - NibLoadableView (tự lấy UINib từ tên class)
public protocol NibLoadableView: AnyObject {
    static var nib: UINib { get }
}

public extension NibLoadableView where Self: UIView {
    static var nib: UINib {
        return UINib(nibName: String(describing: Self.self),
                     bundle: Bundle(for: Self.self))
    }
}

// MARK: - View Reusable
public extension UIView {
    
    static var reuseIdentifier: String {
        return String(describing: self)
    }
    
    static var nibName: String {
        return String(describing: self)
    }
    
    static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: Self.self))
    }
}

