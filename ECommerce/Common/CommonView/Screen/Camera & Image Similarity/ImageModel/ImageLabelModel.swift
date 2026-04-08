//
//  ImageLabelModel.swift
//  ECommerce
//
//  Created by AI Assistant on 26/1/26.
//
//  Refactored to use CameraObservable instead of RxSwift

import UIKit
import CoreVideo

enum SearchTimeoutError: Error {
    case timeout
}

final class ImageProcessingViewModel {

    // MARK: - Input (using CameraObservable)
    let classifyTrigger = CameraEventStream<UIImage>()
    let stopCameraTrigger = CameraEventStream<Void>()
    let pixelBufferStream = CameraEventStream<CVPixelBuffer>()

    // MARK: - Output (using CameraObservable)
    let classifiedLabel: CameraDriver<String>
    let confidenceLabel: CameraDriver<String>
    let topLabels = CameraEventStream<[(String, Double)]>()
    let isProcessing: CameraDriver<Bool>
    let error: CameraDriver<String>

    let searchTrigger = CameraEventStream<UIImage>()
    let showHintTrigger = CameraEventStream<Void>()
    let isCameraRunning = CameraBehaviorStream<Bool>(false)

    // MARK: - Private
    private let aiService: CameraAILabelServiceType
    private let disposalBag = CameraDisposalBag()
    private var processingDisposable: CameraDisposable?
    
    // Keep warmupTimer streams alive to prevent observer disposal
    private var warmupTimerStream: CameraEventStream<Void>?
    private var warmupTimer: CameraEventStream<Void>?

    private let targetWidth = 224
    private let targetHeight = 224

    var cameraStartTime = Date()
    private let hintDelay: TimeInterval = 2.8
    
    // Keep signals alive to ensure observers receive events
    private var searchSignal: CameraEventStream<Bool>?
    private var timeoutSignal: CameraEventStream<Bool>?
    
    // Keep intermediate streams alive to prevent deallocation
    private var timerStream: CameraEventStream<Void>?
    private var doStream: CameraEventStream<Void>?

    let isProcessingModel = CameraBehaviorStream<Bool>(false)
    private let didStartProcessing = CameraBehaviorStream<Bool>(false)

    private let activity = CameraActivityIndicator()
    private let errorTracker = CameraEventStream<Error>()
    private let classifiedLabelSubject = CameraEventStream<String>()
    private let confidenceLabelSubject = CameraEventStream<String>()

    private let cancelProcessingTrigger = CameraEventStream<Void>()

    init(aiService: CameraAILabelServiceType = CameraAILabelService()) {
        print("🤖 [ImageProcessingVM] ========================================")
        print("🤖 [ImageProcessingVM] 🎬 INIT - ImageProcessingViewModel")
        print("🤖 [ImageProcessingVM] ========================================")
        
        self.aiService = aiService
        self.isCameraRunning.accept(true)
        print("🤖 [ImageProcessingVM] ✅ isCameraRunning set to true")

        // Setup Drivers - convert EventStreams to Drivers
        print("🤖 [ImageProcessingVM] 🔗 Setting up Drivers...")
        let classifiedDriverStream = CameraEventStream<String>()
        classifiedLabelSubject.observe(on: classifiedDriverStream, observerBlock: { value in
            classifiedDriverStream.emit(value)
        })
        self.classifiedLabel = CameraDriver(source: classifiedDriverStream)

        let confidenceDriverStream = CameraEventStream<String>()
        confidenceLabelSubject.observe(on: confidenceDriverStream, observerBlock: { value in
            confidenceDriverStream.emit(value)
        })
        self.confidenceLabel = CameraDriver(source: confidenceDriverStream)

        self.isProcessing = activity.asDriver

        let errorDriverStream = CameraEventStream<String>()
        errorTracker.map { $0.localizedDescription }
            .observe(on: errorDriverStream, observerBlock: { value in
                errorDriverStream.emit(value)
            })
        self.error = CameraDriver(source: errorDriverStream)
        print("🤖 [ImageProcessingVM] ✅ All Drivers setup complete")
        
        // Set default values
        classifiedLabelSubject.emit("Cannot classify")
        confidenceLabelSubject.emit("")
        print("🤖 [ImageProcessingVM] ✅ Default values set")

        print("🤖 [ImageProcessingVM] 🔧 Setting up processing pipelines...")
        setupCameraProcessing()
        setupSearchTriggerWithTimeout()
        setupClassifyTrigger()
        setupStopCameraTrigger()
        print("🤖 [ImageProcessingVM] ✅ All pipelines setup complete!")
    }

    private func setupCameraProcessing() {
        print("🤖 [ImageProcessingVM] ========================================")
        print("🤖 [ImageProcessingVM] 🔧 setupCameraProcessing() called")
        print("🤖 [ImageProcessingVM] ========================================")
        
        processingDisposable?.dispose()
        
        // Warmup timer - emits after 1666ms
        print("🤖 [ImageProcessingVM] ⏰ Creating warmup timer (1.666s)...")
        let warmupTimerStream = CameraEventStream<Void>.timer(1.666, queue: DispatchQueue.main)
        // Keep warmupTimerStream alive to prevent observer disposal
        self.warmupTimerStream = warmupTimerStream
        print("🤖 [ImageProcessingVM] ✅ Warmup timer stream created and retained")
        
        // Subscribe to warmup timer to confirm it fires
        let warmupDisposable = warmupTimerStream.observe(on: self, queue: DispatchQueue.main, observerBlock: { [weak self] _ in
            let elapsed = Date().timeIntervalSince(self?.cameraStartTime ?? Date())
            print("🤖 [ImageProcessingVM] ========================================")
            print("🤖 [ImageProcessingVM] ⏰ WARMUP TIMER FIRED!")
            print("🤖 [ImageProcessingVM] ⏱️ Elapsed: \(String(format: "%.3f", elapsed))s")
            print("🤖 [ImageProcessingVM] ========================================")
        })
        disposalBag.add { warmupDisposable.dispose() }
        
        let warmupTimer = warmupTimerStream.takeFirst()
        // Keep warmupTimer stream alive to prevent observer disposal
        self.warmupTimer = warmupTimer
        print("🤖 [ImageProcessingVM] ✅ Warmup timer with takeFirst() created and retained")

        // Background queue for processing
        let backgroundQueue = DispatchQueue(label: "com.camera.processing", qos: .userInitiated)
        print("🤖 [ImageProcessingVM] ✅ Background queue created: \(backgroundQueue.label)")

        print("🤖 [ImageProcessingVM] 🔗 Setting up pixelBufferStream pipeline...")
        print("🤖 [ImageProcessingVM] 📊 Subscribing to pixelBufferStream...")
        
        // Debug: Subscribe to raw pixelBufferStream to see if frames arrive
        let debugDisposable = pixelBufferStream.observe(on: self, queue: DispatchQueue.main, observerBlock: { [weak self] buffer in
            let elapsed = Date().timeIntervalSince(self?.cameraStartTime ?? Date())
            let width = CVPixelBufferGetWidth(buffer)
            let height = CVPixelBufferGetHeight(buffer)
            print("🤖 [ImageProcessingVM] 📹 RAW FRAME received in ViewModel: \(width)x\(height), elapsed: \(String(format: "%.3f", elapsed))s")
        })
        disposalBag.add { debugDisposable.dispose() }
        
        let processedStream = pixelBufferStream
            .skip(until: warmupTimer)
            .do(onNext: { _ in 
                print("🤖 [ImageProcessingVM] ========================================")
                print("🤖 [ImageProcessingVM] 📸 FRAME PASSED WARMUP - Processing!")
                print("🤖 [ImageProcessingVM] ========================================")
            })
            .throttle(0.5, queue: DispatchQueue.main)
            .do(onNext: { _ in
                print("🤖 [ImageProcessingVM] ✅ Frame passed throttle")
            })
            .filter { [weak self] _ in
                guard let self = self else { return false }
                let cameraRunning = self.isCameraRunning.value
                let notProcessing = !self.isProcessingModel.value
                let allowed = cameraRunning && notProcessing
                if !allowed {
                    print("🤖 [ImageProcessingVM] 🚫 Frame blocked - cameraRunning: \(cameraRunning), notProcessing: \(notProcessing)")
                } else {
                    print("🤖 [ImageProcessingVM] ✅ Frame passed camera running check")
                }
                return allowed
            }
            .filter { [weak self] _ in
                guard let self = self else { return false }
                let elapsed = Date().timeIntervalSince(self.cameraStartTime)
                let pass = elapsed >= 1.666
                if !pass {
                    print("🤖 [ImageProcessingVM] ⏳ Dropped frame - elapsed: \(String(format: "%.2f", elapsed))s < 1.666s")
                } else {
                    print("🤖 [ImageProcessingVM] ✅ Frame passed warmup check - elapsed: \(String(format: "%.2f", elapsed))s")
                }
                return pass
            }
            .flatMapLatest { [weak self] buffer -> CameraEventStream<(CVPixelBuffer, [(String, Double)])> in
                guard let self = self else { return CameraEventStream<(CVPixelBuffer, [(String, Double)])>.empty() }
                let width = CVPixelBufferGetWidth(buffer)
                let height = CVPixelBufferGetHeight(buffer)
                print("🤖 [ImageProcessingVM] ========================================")
                print("🤖 [ImageProcessingVM] 🔍 Start AI classification")
                print("🤖 [ImageProcessingVM] 📹 Buffer size: \(width)x\(height)")
                print("🤖 [ImageProcessingVM] ========================================")

                let processingBuffer: CVPixelBuffer
                if CVPixelBufferGetPixelFormatType(buffer) != kCVPixelFormatType_32BGRA ||
                   CVPixelBufferGetWidth(buffer) != self.targetWidth ||
                   CVPixelBufferGetHeight(buffer) != self.targetHeight {
                    guard let convertedBuffer = self.convertToBGRAAndResize(
                        pixelBuffer: buffer,
                        targetWidth: self.targetWidth,
                        targetHeight: self.targetHeight
                    ) else {
                        return CameraEventStream<(CVPixelBuffer, [(String, Double)])>.empty()
                    }
                    processingBuffer = convertedBuffer
                } else {
                    processingBuffer = buffer
                }

                // Use CameraAILabelService (no RxSwift dependency)
                print("🤖 [ImageProcessingVM] 🤖 Calling AI service for classification...")
                let resultStream = CameraEventStream<(CVPixelBuffer, [(String, Double)])>()
                let labelsStream = self.aiService.extractTopLabelsCameraObservable(
                    from: processingBuffer,
                    topK: 3,
                    threshold: 0.1
                )
                print("🤖 [ImageProcessingVM] ✅ AI service called, waiting for results...")
                
                // Create a holder to keep both the disposable and resultStream alive
                // This ensures the observer stays alive until resultStream is deallocated
                class ResultStreamHolder {
                    var disposable: CameraDisposable?
                    let resultStream: CameraEventStream<(CVPixelBuffer, [(String, Double)])>
                    init(resultStream: CameraEventStream<(CVPixelBuffer, [(String, Double)])>) {
                        self.resultStream = resultStream
                    }
                }
                let holder = ResultStreamHolder(resultStream: resultStream)
                
                // Process on background queue - MUST keep disposable alive
                print("🤖 [ImageProcessingVM] 📡 Subscribing to labelsStream...")
                holder.disposable = labelsStream.observe(on: holder.resultStream, queue: backgroundQueue, observerBlock: { labels in
                    print("🤖 [ImageProcessingVM] 🎯 AI classification result received:")
                    for (index, (label, confidence)) in labels.enumerated() {
                        print("🤖 [ImageProcessingVM]   \(index + 1). \(label): \(String(format: "%.2f", confidence * 100))%")
                    }
                    print("🤖 [ImageProcessingVM] 📤 Emitting result to resultStream...")
                    holder.resultStream.emit((processingBuffer, labels))
                    print("🤖 [ImageProcessingVM] ✅ Result emitted to resultStream")
                })
                print("🤖 [ImageProcessingVM] ✅ Observer subscribed to labelsStream, disposable retained")
                
                // Store holder in resultStream to keep disposable and resultStream alive
                resultStream._operatorHolder = holder
                print("🤖 [ImageProcessingVM] ✅ Holder stored in resultStream")
                
                return resultStream
            }
            .filter { (_, topK) in
                guard let first = topK.first else {
                    print("🤖 [ImageProcessingVM] ❌ No labels returned from AI")
                    return false
                }
                let pass = first.1 > 0.33
                print("🤖 [ImageProcessingVM] \(pass ? "✅" : "❌") Confidence filter: \(String(format: "%.2f", first.1 * 100))% - \(pass ? "PASSED" : "FAILED")")
                return pass
            }
            .filter { [weak self] _ in
                guard let self = self else { return false }
                let canProcess = !self.isProcessingModel.value
                if !canProcess {
                    print("🤖 [ImageProcessingVM] 🚫 Skipping frame - already processing (isProcessingModel = true)")
                } else {
                    print("🤖 [ImageProcessingVM] ✅ Frame passed processing lock check")
                }
                return canProcess
            }
            .takeFirst()

        print("🤖 [ImageProcessingVM] ✅ Pipeline setup complete, subscribing to processed stream...")
        processingDisposable = processedStream.observe(on: self, queue: DispatchQueue.main, observerBlock: { [weak self] (buffer: CVPixelBuffer, topK: [(String, Double)]) in
            guard let self = self else { return }
            
            let elapsed = Date().timeIntervalSince(self.cameraStartTime)
            print("🤖 [ImageProcessingVM] ========================================")
            print("🤖 [ImageProcessingVM] 🎯 FIRST QUALIFYING FRAME PROCESSED!")
            print("🤖 [ImageProcessingVM] ⏱️ Elapsed time: \(String(format: "%.2f", elapsed))s")
            print("🤖 [ImageProcessingVM] 📊 Top labels:")
            for (index, (label, confidence)) in topK.enumerated() {
                print("🤖 [ImageProcessingVM]   \(index + 1). \(label): \(String(format: "%.1f", confidence * 100))%")
            }
            print("🤖 [ImageProcessingVM] ========================================")
            
            self.isProcessingModel.accept(true)
            print("🤖 [ImageProcessingVM] 🔒 Set isProcessingModel = true (blocking further frames)")
            
            self.topLabels.emit(topK)
            print("🤖 [ImageProcessingVM] 📤 Emitted topLabels")

            if let first = topK.first {
                self.classifiedLabelSubject.emit(first.0)
                self.confidenceLabelSubject.emit("Confidence: \(Int(first.1 * 100))%")
                print("🤖 [ImageProcessingVM] 📤 Emitted classifiedLabel: \(first.0)")
                print("🤖 [ImageProcessingVM] 📤 Emitted confidenceLabel: \(Int(first.1 * 100))%")
            }

            if let uiImage = UIImage(pixelBuffer: buffer) {
                print("🤖 [ImageProcessingVM] 🖼️ Converted buffer to UIImage: \(uiImage.size)")
                print("🤖 [ImageProcessingVM] 🔗 Emitting searchTrigger...")
                self.searchTrigger.emit(uiImage)
                print("🤖 [ImageProcessingVM] ✅ searchTrigger emitted!")
            } else {
                print("🤖 [ImageProcessingVM] ❌ ERROR: Cannot convert buffer to UIImage")
            }
        })
        
        disposalBag.add { [weak self] in
            self?.processingDisposable?.dispose()
        }
    }

    private func setupSearchTriggerWithTimeout() {
        print("🤖 [ImageProcessingVM] ========================================")
        print("🤖 [ImageProcessingVM] ⏰ Setting up timeout mechanism")
        print("🤖 [ImageProcessingVM] ⏱️ Timeout delay: \(hintDelay)s")
        print("🤖 [ImageProcessingVM] ========================================")

        let searchSignal = searchTrigger
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                let elapsed = Date().timeIntervalSince(self.cameraStartTime)
                print("🤖 [ImageProcessingVM] ========================================")
                print("🤖 [ImageProcessingVM] 🔍 SEARCH SIGNAL EMITTED!")
                print("🤖 [ImageProcessingVM] ⏱️ Elapsed: \(String(format: "%.2f", elapsed))s")
                print("🤖 [ImageProcessingVM] ========================================")
            })
            .map { _ in true }
        
        // Keep searchSignal alive to ensure observer receives events
        self.searchSignal = searchSignal

        print("🤖 [ImageProcessingVM] ⏰ Creating timeout timer (\(hintDelay)s)...")
        let timerStream = CameraEventStream<Void>
            .timer(hintDelay, queue: DispatchQueue.main)
        
        // Keep timerStream alive to ensure it doesn't get deallocated
        self.timerStream = timerStream
        
        let doStream = timerStream
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                let elapsed = Date().timeIntervalSince(self.cameraStartTime)
                print("🤖 [ImageProcessingVM] ========================================")
                print("🤖 [ImageProcessingVM] ⏰ TIMEOUT TRIGGERED!")
                print("🤖 [ImageProcessingVM] ⏱️ Elapsed: \(String(format: "%.2f", elapsed))s")
                print("🤖 [ImageProcessingVM] ========================================")
            })
        
        // Keep doStream alive to ensure observer doesn't get disposed
        self.doStream = doStream
        
        let timeoutSignal = doStream
            .map { _ in false }
        
        // Keep timeoutSignal alive to ensure observer receives timeout events
        self.timeoutSignal = timeoutSignal

        print("🤖 [ImageProcessingVM] 🏁 Setting up AMB race (searchSignal vs timeoutSignal)...")
        let ambDisposable = CameraEventStream<Any>.amb([searchSignal, timeoutSignal])
            .takeFirst()
            .observe(on: self, queue: DispatchQueue.main, observerBlock: { [weak self] (isSearchSuccess: Bool) in
                guard let self = self else { return }
                
                let elapsed = Date().timeIntervalSince(self.cameraStartTime)
                print("🤖 [ImageProcessingVM] ========================================")
                print("🤖 [ImageProcessingVM] 🎯 AMB RESULT RECEIVED")
                print("🤖 [ImageProcessingVM] ⏱️ Total elapsed: \(String(format: "%.2f", elapsed))s")
                print("🤖 [ImageProcessingVM] 📊 Result: \(isSearchSuccess ? "SUCCESS (found)" : "TIMEOUT (not found)")")
                print("🤖 [ImageProcessingVM] ========================================")
                
                if isSearchSuccess {
                    print("🤖 [ImageProcessingVM] ✅ Found result in \(String(format: "%.2f", elapsed))s - Result found, NOT dismissing (user can swipe down)")
                    // Don't auto-dismiss - let user swipe down manually
                    // Just show the result
                } else {
                    print("🤖 [ImageProcessingVM] ⚠️ Timeout after \(String(format: "%.2f", elapsed))s - Showing hint")
                    self.showHintTrigger.emit(())
                }
            })
        // Keep disposable alive to ensure observer receives timeout events
        disposalBag.add {
            ambDisposable.dispose()
        }
        print("🤖 [ImageProcessingVM] ✅ Timeout mechanism setup complete (disposable retained)")
    }

    private func setupClassifyTrigger() {
        classifyTrigger
            .flatMapLatest { [weak self] image -> CameraEventStream<[(String, Double)]> in
                guard let self = self else { return CameraEventStream<[(String, Double)]>.empty() }
                
                let resultStream = CameraEventStream<[(String, Double)]>()
                let labelsStream = self.aiService.extractTopLabelsCameraObservable(
                    from: image,
                    topK: 3,
                    threshold: 0.1
                )
                
                // Track activity
                activity.isActive.accept(true)
                
                labelsStream.observe(on: resultStream, observerBlock: { labels in
                    self.activity.isActive.accept(false)
                    resultStream.emit(labels)
                })
                
                return resultStream
            }
            .observe(on: self, queue: DispatchQueue.main, observerBlock: { [weak self] (topK: [(String, Double)]) in
                guard let self = self else { return }
                self.topLabels.emit(topK)
                if let first = topK.first {
                    self.classifiedLabelSubject.emit(first.0)
                    self.confidenceLabelSubject.emit("Confidence: \(Int(first.1 * 100))%")
                } else {
                    self.classifiedLabelSubject.emit("Cannot classify")
                    self.confidenceLabelSubject.emit("")
                }
            })
    }

    private func setupStopCameraTrigger() {
        stopCameraTrigger
            .delay(0.3, queue: DispatchQueue.main)
            .observe(on: self, queue: DispatchQueue.main, observerBlock: { [weak self] (_: Void) in
                guard let self = self else { return }
                print("[Camera] 🛑 stopCameraTrigger called → reset state")
                self.resetAllState()
            })
    }

    func resetAllState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let oldCameraRunning = self.isCameraRunning.value
            let oldDidStartProcessing = self.didStartProcessing.value
            
            self.didStartProcessing.accept(false)
            self.isProcessingModel.accept(false)
            self.cameraStartTime = Date()
            
            print("[Camera] 🔄 State reset: isCameraRunning \(oldCameraRunning)→false, didStartProcessing \(oldDidStartProcessing)→false")
        }
    }
    
    func convertToBGRAAndResize(pixelBuffer: CVPixelBuffer, targetWidth: Int, targetHeight: Int) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        var bgraPixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            nil,
            targetWidth,
            targetHeight,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &bgraPixelBuffer
        )

        guard let outputBuffer = bgraPixelBuffer else { return nil }

        let scaleX = CGFloat(targetWidth) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let scaleY = CGFloat(targetHeight) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let resizedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        context.render(resizedImage, to: outputBuffer)
        return outputBuffer
    }
}
