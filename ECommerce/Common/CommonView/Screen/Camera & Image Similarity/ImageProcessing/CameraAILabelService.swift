//
//  CameraAILabelService.swift
//  ECommerce
//
//  Created by AI Assistant on 26/1/26.
//
//  Camera-specific AI Label Service - No RxSwift dependency
//  Wraps CoreML model directly for Camera module

import UIKit
import CoreML
import CoreVideo

/// Protocol for AI Label Service in Camera module (no RxSwift)
/// Internal access - accessible within Camera module
internal protocol CameraAILabelServiceType {
    func extractTopLabels(from pixelBuffer: CVPixelBuffer, 
                         topK: Int, 
                         threshold: Double,
                         completion: @escaping (Result<[(String, Double)], Error>) -> Void)
    
    func extractTopLabels(from image: UIImage,
                         topK: Int,
                         threshold: Double,
                         completion: @escaping (Result<[(String, Double)], Error>) -> Void)
}

/// Camera AI Label Service implementation - No RxSwift
final class CameraAILabelService: CameraAILabelServiceType {
    private let model: MobileNetV2
    private let targetSize = 224
    
    init() {
        // Tối ưu: Sử dụng ANE (Neural Engine) để tăng tốc
        let config = MLModelConfiguration()
        config.computeUnits = .cpuOnly
        self.model = try! MobileNetV2(configuration: config)
    }
    
    // MARK: - Extract Top Labels from CVPixelBuffer
    
    func extractTopLabels(from pixelBuffer: CVPixelBuffer,
                         topK: Int = 3,
                         threshold: Double = 0.1,
                         completion: @escaping (Result<[(String, Double)], Error>) -> Void) {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        print("🤖 [AILabelService] ========================================")
        print("🤖 [AILabelService] 🔍 Starting AI classification")
        print("🤖 [AILabelService] 📹 Input: \(width)x\(height), topK: \(topK), threshold: \(threshold)")
        print("🤖 [AILabelService] ========================================")
        
        // Run on background queue to avoid blocking
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                print("🤖 [AILabelService] ❌ Service deallocated")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "CameraAILabelService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                }
                return
            }
            
            print("🤖 [AILabelService] 🧠 Running on background queue...")
            let startTime = Date()
            
            do {
                print("🤖 [AILabelService] 📥 Creating ML model input...")
                let input = MobileNetV2Input(image: pixelBuffer)
                
                print("🤖 [AILabelService] 🧠 Running model prediction...")
                let output = try self.model.prediction(input: input)
                print("🤖 [AILabelService] ✅ Model prediction completed")
                
                // Sắp xếp theo confidence giảm dần, lọc theo threshold
                print("🤖 [AILabelService] 🔍 Processing results (threshold: \(threshold))...")
                let topLabels = output.classLabelProbs
                    .filter { $0.value >= threshold }
                    .sorted { $0.value > $1.value }
                    .prefix(topK)
                
                let result = Array(topLabels)
                let processingTime = Date().timeIntervalSince(startTime)
                
                print("🤖 [AILabelService] 📊 Classification results:")
                for (index, (label, confidence)) in result.enumerated() {
                    print("🤖 [AILabelService]   \(index + 1). \(label): \(String(format: "%.2f", confidence * 100))%")
                }
                print("🤖 [AILabelService] ⏱️ Processing time: \(String(format: "%.3f", processingTime))s")
                print("🤖 [AILabelService] ========================================")
                
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                print("🤖 [AILabelService] ❌ ERROR during prediction: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Extract Top Labels from UIImage
    
    func extractTopLabels(from image: UIImage,
                         topK: Int = 3,
                         threshold: Double = 0.1,
                         completion: @escaping (Result<[(String, Double)], Error>) -> Void) {
        guard let buffer = image.pixelBuffer(width: targetSize, height: targetSize) else {
            completion(.failure(NSError(domain: "CameraAILabelService",
                                       code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "Invalid image"])))
            return
        }
        
        extractTopLabels(from: buffer, topK: topK, threshold: threshold, completion: completion)
    }
}

// MARK: - Extension for CameraObservable Integration

extension CameraAILabelServiceType {
    /// Extract top labels returning CameraObservable (no RxSwift)
    func extractTopLabelsCameraObservable(from pixelBuffer: CVPixelBuffer, 
                                         topK: Int = 3, 
                                         threshold: Double = 0.1) -> CameraEventStream<[(String, Double)]> {
        print("🤖 [AILabelService] 📤 extractTopLabelsCameraObservable called")
        let stream = CameraEventStream<[(String, Double)]>()
        
        // Keep stream alive by storing a reference in _operatorHolder
        // This ensures the stream doesn't get deallocated before the async completion handler is called
        
        let holder = StreamHolder(stream)
        stream._operatorHolder = holder
        
        // Call completion-based API
        extractTopLabels(from: pixelBuffer, topK: topK, threshold: threshold) { result in
            print("🤖 [AILabelService] 📞 Completion handler called")
            switch result {
            case .success(let labels):
                print("🤖 [AILabelService] ✅ Success - Emitting \(labels.count) labels to stream")
                print("🤖 [AILabelService] 📊 Stream observers before emit: checking...")
                stream.emit(labels)
                print("🤖 [AILabelService] ✅ Labels emitted to stream")
            case .failure(let error):
                print("🤖 [AILabelService] ❌ Error: \(error.localizedDescription)")
                print("🤖 [AILabelService] ⚠️ Emitting empty array due to error")
                // Emit empty array on error
                stream.emit([])
            }
        }
        
        return stream
    }
    
    /// Extract top labels from UIImage returning CameraObservable (no RxSwift)
    func extractTopLabelsCameraObservable(from image: UIImage,
                                         topK: Int = 3,
                                         threshold: Double = 0.1) -> CameraEventStream<[(String, Double)]> {
        let stream = CameraEventStream<[(String, Double)]>()
        
        extractTopLabels(from: image, topK: topK, threshold: threshold) { result in
            switch result {
            case .success(let labels):
                stream.emit(labels)
            case .failure(let error):
                print("[CameraAILabelService] Error: \(error.localizedDescription)")
                stream.emit([])
            }
        }
        
        return stream
    }
}

class StreamHolder {
    let stream: CameraEventStream<[(String, Double)]>
    init(_ stream: CameraEventStream<[(String, Double)]>) {
        self.stream = stream
    }
}
