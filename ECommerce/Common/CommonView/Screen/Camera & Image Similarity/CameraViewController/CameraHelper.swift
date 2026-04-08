//
//  CameraHelper.swift
//  ECommerce
//
//  Created by AI Assistant on 26/1/26.
//
//  Helper class to easily present CameraViewController from anywhere in the app

import UIKit

/// Helper class to present CameraViewController
public final class CameraHelper {
    
    /// Present camera with specified mode
    /// - Parameters:
    ///   - mode: Camera mode (.normal or .aiSearch)
    ///   - from: ViewController to present from
    ///   - onImageCaptured: Callback when image is captured (optional)
    ///   - onDismiss: Callback when camera is dismissed (optional)
    public static func presentCamera(
        mode: CameraMode = .normal,
        from viewController: UIViewController,
        onImageCaptured: ((UIImage) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        print("📷 [CameraHelper] ========================================")
        print("📷 [CameraHelper] 🚀 Presenting camera with mode: \(mode == .aiSearch ? "AI_SEARCH" : "NORMAL")")
        print("📷 [CameraHelper] ========================================")
        
        // Try to load from storyboard first
        let storyboard = UIStoryboard(name: "CameraViewController", bundle: Bundle(for: CameraViewController.self))
        let cameraVC: CameraViewController
        
        if let storyboardVC = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as? CameraViewController {
            print("📷 [CameraHelper] ✅ Loaded from storyboard")
            // Storyboard initialization - set mode before viewDidLoad
            cameraVC = storyboardVC
            cameraVC.cameraMode = mode
            print("📷 [CameraHelper] ✅ Set camera mode to: \(mode == .aiSearch ? "AI_SEARCH" : "NORMAL")")
        } else {
            print("📷 [CameraHelper] ⚠️ Storyboard load failed, creating programmatically")
            // Fallback: Create programmatically if storyboard fails
            cameraVC = CameraViewController(mode: mode)
            print("📷 [CameraHelper] ✅ Created programmatically with mode: \(mode == .aiSearch ? "AI_SEARCH" : "NORMAL")")
        }
        
        // Use sheet presentation style for swipe-down dismissal
        cameraVC.modalPresentationStyle = .pageSheet
        
        // Setup callbacks
        if let onImageCaptured = onImageCaptured {
            print("📷 [CameraHelper] ✅ Setup onImageCaptured callback")
            cameraVC.capturedImage.observeOnMain(on: cameraVC) { image in
                print("📷 [CameraHelper] 📸 Image captured callback triggered - size: \(image.size)")
                onImageCaptured(image)
            }
        } else {
            print("📷 [CameraHelper] ⚠️ No onImageCaptured callback provided")
        }
        
        print("📷 [CameraHelper] 🎬 Presenting camera view controller...")
        viewController.present(cameraVC, animated: true) {
            print("📷 [CameraHelper] ✅ Camera presented successfully")
            
            // Configure sheet presentation after presentation
            if #available(iOS 15.0, *) {
                if let sheet = cameraVC.sheetPresentationController {
                    sheet.detents = [.large()]
                    sheet.preferredCornerRadius = 0
                    sheet.prefersGrabberVisible = false
                    print("📷 [CameraHelper] ✅ Sheet presentation configured")
                }
            }
            
            onDismiss?()
        }
    }
    
    /// Present normal camera (just capture photos)
    public static func presentNormalCamera(
        from viewController: UIViewController,
        onImageCaptured: @escaping (UIImage) -> Void
    ) {
        presentCamera(mode: .normal, from: viewController, onImageCaptured: onImageCaptured)
    }
    
    /// Present AI Search camera (with image recognition)
    /// - Parameters:
    ///   - from: ViewController to present from
    ///   - onImageCaptured: Callback when image is captured (optional)
    ///   - onLabelsDetected: Callback when labels are detected (optional)
    ///   - onDismiss: Callback when camera is dismissed (optional)
    public static func presentAISearchCamera(
        from viewController: UIViewController,
        onImageCaptured: ((UIImage) -> Void)? = nil,
        onLabelsDetected: (([(String, Double)]) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        presentCamera(mode: .aiSearch, from: viewController, onImageCaptured: onImageCaptured, onDismiss: onDismiss)
        
        // Setup labels observer if callback provided
        if let onLabelsDetected = onLabelsDetected {
            // Get cameraVC from presented view controller after a short delay to ensure it's ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let cameraVC = viewController.presentedViewController as? CameraViewController,
                   let viewModel = cameraVC.imViewModel {
                    print("📷 [CameraHelper] ✅ Setting up topLabels observer")
                    
                    // Throttle để tránh gọi callback quá nhiều lần trong thời gian ngắn
                    // Nhưng cho phép manual capture trigger callback ngay cả khi đã có auto detection
                    var lastCallTime: Date?
                    var hasCalledAutoDetection = false
                    let throttleInterval: TimeInterval = 0.3 // Giảm xuống 0.3 giây để cho phép manual capture nhanh hơn
                    
                    // Track manual capture để bypass throttle
                    var isManualCapturePending = false
                    
                    // Observe classifyTrigger để detect manual capture
                    let classifyDisposable = viewModel.classifyTrigger.observeOnMain(on: cameraVC) { _ in
                        print("📷 [CameraHelper] Manual capture detected via classifyTrigger - bypassing throttle")
                        isManualCapturePending = true
                        lastCallTime = nil // Reset throttle để cho phép callback ngay
                    }
                    cameraVC.disposalBag.add {
                        classifyDisposable.dispose()
                    }
                    
                    let disposable = viewModel.topLabels.observeOnMain(on: cameraVC) { labels in
                        guard !labels.isEmpty else {
                            print("⚠️ [CameraHelper] Empty labels, skipping")
                            return
                        }
                        
                        // Throttle: chỉ áp dụng cho auto detection, không áp dụng cho manual capture
                        if isManualCapturePending {
                            // Manual capture: bypass throttle và reset flag
                            print("📷 [CameraHelper] Processing manual capture - bypassing throttle")
                            isManualCapturePending = false
                            lastCallTime = nil
                        } else {
                            // Auto detection: áp dụng throttle
                            let now = Date()
                            if let lastCall = lastCallTime, now.timeIntervalSince(lastCall) < throttleInterval {
                                print("⚠️ [CameraHelper] Throttling: too soon since last call, skipping")
                                return
                            }
                            lastCallTime = now
                            hasCalledAutoDetection = true
                        }
                        
                        print("📷 [CameraHelper] 🏷️ Labels detected: \(labels.count) labels")
                        for (index, (label, confidence)) in labels.enumerated() {
                            print("📷 [CameraHelper]   \(index + 1). \(label): \(String(format: "%.2f", confidence * 100))%")
                        }
                        onLabelsDetected(labels)
                    }
                    // Keep disposable alive
                    cameraVC.disposalBag.add {
                        disposable.dispose()
                    }
                } else {
                    print("⚠️ [CameraHelper] CameraViewController or ViewModel not found")
                }
            }
        }
    }
}
