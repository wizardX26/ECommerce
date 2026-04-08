//
//  UIViewController+Camera.swift
//  ECommerce
//
//  Created by AI Assistant on 26/1/26.
//
//  Extension để dễ dàng mở camera từ bất kỳ UIViewController nào

import UIKit

extension UIViewController {
    
    /// Mở camera thông thường (chỉ chụp ảnh)
    /// - Parameter onImageCaptured: Callback khi có ảnh được chụp
    func presentNormalCamera(onImageCaptured: @escaping (UIImage) -> Void) {
        CameraHelper.presentNormalCamera(from: self, onImageCaptured: onImageCaptured)
    }
    
    /// Mở camera với AI Search (tìm kiếm bằng hình ảnh)
    /// - Parameters:
    ///   - onImageCaptured: Callback khi có ảnh được chụp (optional)
    ///   - onLabelsDetected: Callback khi labels được detect (optional)
    ///   - onDismiss: Callback khi camera dismiss (optional)
    func presentAISearchCamera(
        onImageCaptured: ((UIImage) -> Void)? = nil,
        onLabelsDetected: (([(String, Double)]) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        CameraHelper.presentAISearchCamera(
            from: self,
            onImageCaptured: onImageCaptured,
            onLabelsDetected: onLabelsDetected,
            onDismiss: onDismiss
        )
    }
    
    /// Mở camera với mode tùy chọn
    /// - Parameters:
    ///   - mode: Camera mode (.normal hoặc .aiSearch)
    ///   - onImageCaptured: Callback khi có ảnh được chụp (optional)
    ///   - onDismiss: Callback khi camera dismiss (optional)
    func presentCamera(
        mode: CameraMode,
        onImageCaptured: ((UIImage) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        CameraHelper.presentCamera(
            mode: mode,
            from: self,
            onImageCaptured: onImageCaptured,
            onDismiss: onDismiss
        )
    }
}
