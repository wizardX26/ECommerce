//
//  UIImageExtensions.swift
//  CoreUtilsKit
//
//  Created by Bui Thien Thien on 9/28/20.
//  Copyright © 2020 ViettelPay App Team. All rights reserved.
//

import UIKit

public extension UIImageView {
    /// Load image to UIImageView from URL with placeholder image
    /// - Parameters:
    ///   - url: url to load image
    ///   - placeHolderImage: placeholder image
    ///   - completion: completion block with 2 arguments: error and image
    func load(url: URL, placeHolderImage: UIImage? = nil, completion:((_ error: Error?, _ image: UIImage?) -> Void)? = nil) {
//        let sdWebImageCallBack: SDExternalCompletionBlock = {(image, error, cacheType, imageURL) -> Void  in
//            completion?(error, image)
//        }
//        sd_setImage(with:url, placeholderImage: placeHolderImage, completed:sdWebImageCallBack)

//        kf.setImage(with: url, placeholder: placeHolderImage, completionHandler:  { image, error, cacheType, imageURL in
//            completion?(error, image)
//        })
    }
    
    /// Load image to UIImageView from URL string with placeholder image
    /// - Parameters:
    ///   - url: url string to load image
    ///   - placeHolderImage: placeholder image
    ///   - completion: completion block with 2 arguments: error and image
    func load(urlString: String, placeHolderImage: UIImage? = nil, completion:((_ error: Error?, _ image: UIImage?) -> Void)? = nil) {
        if let url = URL(string: urlString) {
            load(url: url, placeHolderImage: placeHolderImage, completion: completion)
        } else {
            completion?(nil, nil)
        }
    }
    
    /// Set image to UIImageView with CrossDissolve effect
    /// - Parameters:
    ///   - image: Target image
    ///   - animated: Transition with animation or not (default is true)
    @objc
    func setImage(_ image:UIImage?, animated: Bool = true) {
        let duration = animated ? 0.2 : 0.0
        UIView.transition(with: self, duration: duration, options: .transitionCrossDissolve, animations: {
            self.image = image
        }, completion: nil)
    }
}

public extension UIImage {
    // Generate image with UIView
    class func imageWithView(_ view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0)
        defer { UIGraphicsEndImageContext() }
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
    
    func parseQR() -> [String] {
        guard let image = CIImage(image: self) else {
            return []
        }
        
        let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                  context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        let features = detector?.features(in: image) ?? []
        
        return features.compactMap { feature in
            return (feature as? CIQRCodeFeature)?.messageString
        }
    }

    func roundedImage(borderWidth: CGFloat? = nil, borderColor: UIColor? = nil) -> UIImage {
        let imageView: UIImageView = UIImageView(image: self)
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        let layer = imageView.layer
        layer.masksToBounds = true
        layer.cornerRadius = imageView.bounds.size.width / 2.0
        if let borderWidth = borderWidth, let borderColor = borderColor {
            layer.borderWidth = borderWidth
            layer.borderColor = borderColor.cgColor
        }
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, self.scale)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return roundedImage!
    }
}
