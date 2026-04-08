//
//  ProductDetailDIContainer.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit

protocol ProductDetailCoordinatingControllerDependencies {
    func makeProductDetailViewController(productItem: ProductItemModel) -> ProductDetailViewController
}

final class ProductDetailDIContainer: ProductDetailCoordinatingControllerDependencies {
    
    struct Dependencies {
        // No external dependencies needed for ProductDetail
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies = Dependencies()) {
        self.dependencies = dependencies
    }
    
    // MARK: - Product Detail Scene
    
    func makeProductDetailViewController(productItem: ProductItemModel) -> ProductDetailViewController {
        print("🔵 [ProductDetailDIContainer] makeProductDetailViewController called")
        print("   📦 Product: \(productItem.name) (ID: \(productItem.id))")
        print("   🔧 Creating ProductDetailController...")
        let controller = makeProductDetailController(productItem: productItem)
        print("   ✅ ProductDetailController created")
        print("   🔧 Creating ProductDetailViewController...")
        let viewController = ProductDetailViewController.create(with: controller)
        print("   ✅ ProductDetailViewController created")
        return viewController
    }
    
    func makeProductDetailController(productItem: ProductItemModel) -> ProductDetailController {
        print("   🔧 [ProductDetailDIContainer] Creating DefaultProductDetailController...")
        let controller = DefaultProductDetailController(productItem: productItem)
        print("   ✅ DefaultProductDetailController created")
        return controller
    }
    
    // MARK: - Flow Coordinators
    
    func makeProductDetailCoordinatingController(
        navigationController: UINavigationController
    ) -> ProductDetailCoordinatingController {
        ProductDetailCoordinatingController(
            navigationController: navigationController,
            dependencies: self
        )
    }
}
