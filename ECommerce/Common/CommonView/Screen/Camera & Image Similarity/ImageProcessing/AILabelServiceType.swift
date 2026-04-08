//
//  AIEmbeddingService.swift
//  AI integration sample
//
//  Created by Nguyen Duc Hung on 27/9/25.
//
//  ⚠️ REFACTORED TO USE CameraObservable
//  This file has been refactored to use CameraObservable instead of RxSwift Observable
//  for use within Camera & Image Similarity module

import UIKit
import CoreML
import CoreVideo

/// Protocol for AI Label Service using CameraObservable (NO RxSwift)
protocol AILabelServiceType {
    func extractLabel(from pixelBuffer: CVPixelBuffer) -> CameraEventStream<String>
    func extractLabel(from image: UIImage) -> CameraEventStream<String>
    
    // TopK labels với confidence
    func extractTopLabels(from pixelBuffer: CVPixelBuffer, topK: Int, threshold: Double) -> CameraEventStream<[(String, Double)]>
    func extractTopLabels(from image: UIImage, topK: Int, threshold: Double) -> CameraEventStream<[(String, Double)]>
}

/// AI Label Service implementation using CameraObservable (NO RxSwift)
final class AILabelService: AILabelServiceType {
    private let model: MobileNetV2
    private let targetSize = 224
    
    init() {
        // Tối ưu: Sử dụng ANE (Neural Engine) để tăng tốc
        let config = MLModelConfiguration()
        config.computeUnits = .cpuOnly
        self.model = try! MobileNetV2(configuration: config)
    }
    
    // MARK: - Predict từ CVPixelBuffer (label duy nhất)
    func extractLabel(from pixelBuffer: CVPixelBuffer) -> CameraEventStream<String> {
        let stream = CameraEventStream<String>()
        
        // Run on background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    stream.emit("Error: Service deallocated")
                }
                return
            }
            
            do {
                let input = MobileNetV2Input(image: pixelBuffer)
                let output = try self.model.prediction(input: input)
                
                DispatchQueue.main.async {
                    stream.emit(output.classLabel)
                }
            } catch {
                DispatchQueue.main.async {
                    stream.emit("Error: \(error.localizedDescription)")
                }
            }
        }
        
        return stream
    }
    
    // MARK: - Predict từ UIImage (label duy nhất)
    func extractLabel(from image: UIImage) -> CameraEventStream<String> {
        let stream = CameraEventStream<String>()
        
        guard let buffer = image.pixelBuffer(width: targetSize, height: targetSize) else {
            stream.emit("Error: Invalid image")
            return stream
        }
        
        // Forward to pixelBuffer version
        let labelStream = extractLabel(from: buffer)
        labelStream.observe(on: stream, observerBlock: { label in
            stream.emit(label)
        })
        
        return stream
    }
    
    // MARK: - TopK labels từ CVPixelBuffer
    func extractTopLabels(from pixelBuffer: CVPixelBuffer, topK: Int = 3, threshold: Double = 0.1) -> CameraEventStream<[(String, Double)]> {
        let stream = CameraEventStream<[(String, Double)]>()
        
        // Run on background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    stream.emit([])
                }
                return
            }
            
            do {
                let input = MobileNetV2Input(image: pixelBuffer)
                let output = try self.model.prediction(input: input)
                
                // Sắp xếp theo confidence giảm dần, lọc theo threshold
                let topLabels = output.classLabelProbs
                    .filter { $0.value >= threshold }
                    .sorted { $0.value > $1.value }
                    .prefix(topK)
                
                DispatchQueue.main.async {
                    stream.emit(Array(topLabels))
                }
            } catch {
                DispatchQueue.main.async {
                    print("[AILabelService] Error: \(error.localizedDescription)")
                    stream.emit([])
                }
            }
        }
        
        return stream
    }
    
    // MARK: - TopK labels từ UIImage
    func extractTopLabels(from image: UIImage, topK: Int = 3, threshold: Double = 0.1) -> CameraEventStream<[(String, Double)]> {
        let stream = CameraEventStream<[(String, Double)]>()
        
        guard let buffer = image.pixelBuffer(width: targetSize, height: targetSize) else {
            stream.emit([])
            return stream
        }
        
        // Forward to pixelBuffer version
        let labelsStream = extractTopLabels(from: buffer, topK: topK, threshold: threshold)
        labelsStream.observe(on: stream, observerBlock: { labels in
            stream.emit(labels)
        })
        
        return stream
    }
}
