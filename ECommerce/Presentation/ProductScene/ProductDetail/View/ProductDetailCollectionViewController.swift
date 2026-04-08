//
//  ProductDetailCollectionViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit

final class ProductDetailCollectionViewController: UICollectionViewController {
    
    var productDetailController: ProductDetailController?
    
    // Callback để forward quantity changes lên parent
    var onQuantityChanged: ((Int) -> Void)?
    
    private var product: ProductDetailModel? {
        return productDetailController?.product.value
    }
    
    // MARK: - Lifecycle
    
    static func instantiateViewController() -> ProductDetailCollectionViewController {
        let storyboard = UIStoryboard(name: "ProductDetailCollectionViewController", bundle: nil)
        // Use storyboardIdentifier that was set in storyboard
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "ProductDetailCollectionViewController") as? ProductDetailCollectionViewController else {
            fatalError("Cannot instantiate ProductDetailCollectionViewController from storyboard")
        }
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        bindProduct()
    }
    
    // MARK: - Setup
    
    private func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.decelerationRate = .normal // DecelerationRate bình thường để mượt mà hơn
        collectionView.isScrollEnabled = true
        collectionView.alwaysBounceVertical = true
        // Bỏ damping để scroll tự do
        if #available(iOS 13.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        
        // Register cells
        collectionView.register(ProductImageCell.self, forCellWithReuseIdentifier: ProductImageCell.reuseIdentifierProductImage)
        collectionView.register(ProductInfoCell.self, forCellWithReuseIdentifier: ProductInfoCell.reuseIdentifierProductInfo)
        
        // Set custom layout
        if let layout = collectionView.collectionViewLayout as? UltravisualLayout {
            // Layout đã được setup trong storyboard
        } else {
            let layout = UltravisualLayout()
            collectionView.collectionViewLayout = layout
        }
    }
    
    private func bindProduct() {
        productDetailController?.product.observe(on: self) { [weak self] _ in
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2 // Cell ảnh (0) và cell thông tin (1)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let product = product else {
            return UICollectionViewCell()
        }
        
        if indexPath.item == 0 {
            // Cell ảnh sản phẩm
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ProductImageCell.reuseIdentifierProductImage,
                for: indexPath
            ) as! ProductImageCell
            cell.configure(with: product)
            cell.backgroundColor = .clear
            return cell
        } else {
            // Cell thông tin sản phẩm
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ProductInfoCell.reuseIdentifierProductInfo,
                for: indexPath
            ) as! ProductInfoCell
            cell.configure(with: product)
            cell.backgroundColor = .white
            
            // Setup callback để nhận quantity changes từ cell
            cell.onQuantityChanged = { [weak self] quantity in
                self?.onQuantityChanged?(quantity)
            }
            
            return cell
        }
    }
}
