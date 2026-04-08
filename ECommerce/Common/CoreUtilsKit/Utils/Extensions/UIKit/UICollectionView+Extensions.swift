//
//  UICollectionViewExtensions.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

extension UICollectionViewCell: NibLoadableView, ReusableView {}
extension UICollectionReusableView: NibLoadableView, ReusableView {}


// MARK: - UICollectionView Register Support
public extension UICollectionView {

    /// Đăng ký cell, tự nhận diện code-only hay xib
    func register<T: UICollectionViewCell>(cell: T.Type) {
        let nibExists = Bundle(for: T.self)
            .path(forResource: T.reuseIdentifier, ofType: "nib") != nil

        if nibExists {
            register(T.nib, forCellWithReuseIdentifier: T.reuseIdentifier)
        } else {
            register(T.self, forCellWithReuseIdentifier: T.reuseIdentifier)
        }
    }

    /// Đăng ký supplementary view (header/footer), auto detect xib
    func register<T: UICollectionReusableView>(supplementaryView: T.Type,
                                               ofKind kind: String) {
        let nibExists = Bundle(for: T.self)
            .path(forResource: T.reuseIdentifier, ofType: "nib") != nil

        if nibExists {
            register(T.nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: T.reuseIdentifier)
        } else {
            register(T.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: T.reuseIdentifier)
        }
    }
}


// MARK: - UICollectionView Dequeue Support
public extension UICollectionView {

    /// Dequeue cell type-safe
    func dequeueReusableCell<T: UICollectionViewCell>(
        ofType cellType: T.Type = T.self,
        for indexPath: IndexPath
    ) -> T {
        guard let cell = dequeueReusableCell(
            withReuseIdentifier: cellType.reuseIdentifier,
            for: indexPath
        ) as? T else {
            fatalError("❌ Could not dequeue cell: \(cellType.reuseIdentifier)")
        }
        return cell
    }

    /// Dequeue supplementary view type-safe
    func dequeueReusableSupplementaryView<T: UICollectionReusableView>(
        ofType viewType: T.Type = T.self,
        ofKind kind: String,
        for indexPath: IndexPath
    ) -> T {
        guard let view = dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: viewType.reuseIdentifier,
            for: indexPath
        ) as? T else {
            fatalError("❌ Could not dequeue supplementary view: \(viewType.reuseIdentifier)")
        }
        return view
    }
}

extension UICollectionView {
    /// Deselect all selected items (multi-selection)
    func deselectAllItems(animated: Bool = true) {
        guard let selectedIndexPaths = self.indexPathsForSelectedItems else { return }
        for indexPath in selectedIndexPaths {
            self.deselectItem(at: indexPath, animated: animated)
        }
    }
}
