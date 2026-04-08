//
//  CameraObservable.swift
//  ECommerce
//
//  Created by AI Assistant on 26/1/26.
//
//  CameraObservable - Custom reactive framework for Camera module only
//  Replaces RxSwift dependencies in Camera & Image Similarity module

import Foundation
import UIKit

// MARK: - DisposalBag

/// Manages lifecycle of subscriptions
public final class CameraDisposalBag {
    private var disposables: [() -> Void] = []
    
    public init() {}
    
    public func add(_ dispose: @escaping () -> Void) {
        disposables.append(dispose)
    }
    
    deinit {
        disposables.forEach { $0() }
    }
}

// MARK: - Observer

private struct Observer<T> {
    weak var observer: AnyObject?
    let block: (T) -> Void
    let queue: DispatchQueue?
}

// MARK: - EventStream (Replaces PublishSubject/PublishRelay)

// Global emit counter (outside generic context)
private class EmitCounter {
    static let shared = EmitCounter()
    private var counters: [String: Int] = [:]
    private let lockQueue = DispatchQueue(label: "com.camera.observable.emitcounter")
    
    func increment(for typeName: String) -> Int {
        return lockQueue.sync {
            counters[typeName, default: 0] += 1
            return counters[typeName]!
        }
    }
}

/// Event stream that doesn't require initial value
public final class CameraEventStream<Value> {
    private var observers = [Observer<Value>]()
    private let lockQueue = DispatchQueue(label: "com.camera.observable.eventstream", attributes: .concurrent)
    
    // Internal storage for operators to keep observers alive
    var _operatorHolder: AnyObject?
    
    public init() {}
    
    /// Emit a new value to all observers
    public func emit(_ value: Value) {
        lockQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // Debug: Check observers before filtering
            let typeName = String(describing: Value.self)
            let count = EmitCounter.shared.increment(for: typeName)
            
            // Always log for Void type (timer events)
            if typeName == "()" || count <= 3 || count % 50 == 0 {
                let totalObservers = self.observers.count
                let nilObservers = self.observers.filter { $0.observer == nil }.count
                print("📡 [CameraObservable] 📊 Before filter: \(totalObservers) total, \(nilObservers) nil observers (type: \(typeName), count: \(count))")
                
                // Log each observer's state
                for (index, obs) in self.observers.enumerated() {
                    let isNil = obs.observer == nil
                    let queueLabel = obs.queue?.label ?? "sync"
                    print("📡 [CameraObservable] 📋 Observer #\(index + 1): nil=\(isNil), queue=\(queueLabel)")
                }
            }
            
            let activeObservers = self.observers.filter { $0.observer != nil }
            self.observers = activeObservers
            
            if typeName == "()" || count <= 3 || count % 50 == 0 {
                print("📡 [CameraObservable] 📤 Emitting to \(activeObservers.count) active observers (type: \(typeName), count: \(count))")
            }
            
            for (index, observer) in activeObservers.enumerated() {
                if let queue = observer.queue {
                    queue.async {
                        print("📡 [CameraObservable] 🔔 Notifying observer #\(index + 1) on queue: \(queue.label) (type: \(typeName), count: \(count))")
                        observer.block(value)
                    }
                } else {
                    print("📡 [CameraObservable] 🔔 Notifying observer #\(index + 1) synchronously (type: \(typeName), count: \(count))")
                    observer.block(value)
                }
            }
        }
    }
    
    /// Subscribe to events
    public func observe(on observer: AnyObject, 
                       queue: DispatchQueue? = nil,
                       observerBlock: @escaping (Value) -> Void) -> CameraDisposable {
        let observerObj = Observer(observer: observer, block: observerBlock, queue: queue)
        let typeName = String(describing: Value.self)
        
        lockQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.observers.append(observerObj)
            print("📡 [CameraObservable] ✅ Observer added (type: \(typeName), total: \(self.observers.count), queue: \(queue?.label ?? "sync"))")
        }
        
        return CameraDisposable { [weak self] in
            print("📡 [CameraObservable] 🗑️ Disposing observer (type: \(typeName))")
            self?.remove(observer: observer)
        }
    }
    
    /// Observe on main thread
    public func observeOnMain(on observer: AnyObject, 
                             observerBlock: @escaping (Value) -> Void) -> CameraDisposable {
        return observe(on: observer, queue: .main, observerBlock: observerBlock)
    }
    
    /// Remove observer (for manual cleanup)
    public func remove(observer: AnyObject) {
        lockQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.observers = self.observers.filter { $0.observer !== observer }
        }
    }
}

// MARK: - BehaviorStream (Replaces BehaviorRelay)

/// Behavior stream with initial value
public final class CameraBehaviorStream<Value> {
    private var _value: Value
    private var observers = [Observer<Value>]()
    private let lockQueue = DispatchQueue(label: "com.camera.observable.behaviorstream", attributes: .concurrent)
    
    public var value: Value {
        get {
            return lockQueue.sync { _value }
        }
        set {
            lockQueue.async(flags: .barrier) { [weak self] in
                guard let self = self else { return }
                self._value = newValue
                let activeObservers = self.observers.filter { $0.observer != nil }
                self.observers = activeObservers
                
                for observer in activeObservers {
                    if let queue = observer.queue {
                        queue.async {
                            observer.block(newValue)
                        }
                    } else {
                        observer.block(newValue)
                    }
                }
            }
        }
    }
    
    public init(_ value: Value) {
        self._value = value
    }
    
    /// Accept new value (compatible with BehaviorRelay API)
    public func accept(_ value: Value) {
        self.value = value
    }
    
    /// Subscribe to value changes
    public func observe(on observer: AnyObject,
                       queue: DispatchQueue? = nil,
                       observerBlock: @escaping (Value) -> Void) -> CameraDisposable {
        let observerObj = Observer(observer: observer, block: observerBlock, queue: queue)
        
        // Emit current value immediately
        if let queue = queue {
            queue.async {
                observerBlock(self.value)
            }
        } else {
            observerBlock(self.value)
        }
        
        lockQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.observers.append(observerObj)
        }
        
        return CameraDisposable { [weak self] in
            self?.remove(observer: observer)
        }
    }
    
    /// Observe on main thread
    public func observeOnMain(on observer: AnyObject,
                             observerBlock: @escaping (Value) -> Void) -> CameraDisposable {
        return observe(on: observer, queue: .main, observerBlock: observerBlock)
    }
    
    /// Remove observer (for manual cleanup)
    public func remove(observer: AnyObject) {
        lockQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.observers = self.observers.filter { $0.observer !== observer }
        }
    }
}

// MARK: - Driver (Replaces RxSwift Driver)

/// Driver - always emits on main thread, never errors
public final class CameraDriver<Value> {
    private let source: CameraEventStream<Value>
    
    public init(source: CameraEventStream<Value>) {
        self.source = source
    }
    
    /// Subscribe to driver (always on main thread)
    public func drive(on observer: AnyObject,
                     observerBlock: @escaping (Value) -> Void) -> CameraDisposable {
        return source.observeOnMain(on: observer, observerBlock: observerBlock)
    }
}

// MARK: - Disposable

public final class CameraDisposable {
    private let disposeAction: () -> Void
    private var isDisposed = false
    private let lockQueue = DispatchQueue(label: "com.camera.observable.disposable")
    
    init(_ disposeAction: @escaping () -> Void) {
        self.disposeAction = disposeAction
    }
    
    public func dispose() {
        lockQueue.sync {
            guard !isDisposed else { return }
            isDisposed = true
            disposeAction()
        }
    }
    
    deinit {
        dispose()
    }
}

// MARK: - Helper Classes for Operators

/// Helper class to keep observer and disposables alive for operators
private class OperatorHolder {
    let observer = NSObject()
    var disposables: [CameraDisposable] = []
    var additionalData: Any? // For storing additional state (e.g., currentDisposable in flatMapLatest)
}

/// Helper class to hold mutable state for flatMapLatest operator
private class FlatMapState {
    var currentDisposable: CameraDisposable?
    var currentStream: AnyObject? // Keep the current stream alive until disposed
}

// MARK: - Operators Extension

extension CameraEventStream {
    
    /// Map operator
    public func map<U>(_ transform: @escaping (Value) -> U) -> CameraEventStream<U> {
        let mapped = CameraEventStream<U>()
        let holder = OperatorHolder()
        
        let disposable = observe(on: holder.observer, observerBlock: { value in
            mapped.emit(transform(value))
        })
        holder.disposables.append(disposable)
        
        // Store holder to keep observer and disposable alive
        mapped._operatorHolder = holder
        
        return mapped
    }
    
    /// Filter operator
    public func filter(_ predicate: @escaping (Value) -> Bool) -> CameraEventStream<Value> {
        let filtered = CameraEventStream<Value>()
        let holder = OperatorHolder()
        
        let disposable = observe(on: holder.observer, observerBlock: { value in
            if predicate(value) {
                filtered.emit(value)
            }
        })
        holder.disposables.append(disposable)
        
        // Store holder to keep observer and disposable alive
        filtered._operatorHolder = holder
        
        return filtered
    }
    
    /// Throttle operator
    public func throttle(_ interval: TimeInterval, queue: DispatchQueue = .main) -> CameraEventStream<Value> {
        let throttled = CameraEventStream<Value>()
        var lastEmitTime: Date?
        let lockQueue = DispatchQueue(label: "com.camera.observable.throttle")
        let holder = OperatorHolder()
        
        let disposable = observe(on: holder.observer, observerBlock: { value in
            lockQueue.async {
                let now = Date()
                if let lastTime = lastEmitTime {
                    let elapsed = now.timeIntervalSince(lastTime)
                    if elapsed < interval {
                        return
                    }
                }
                lastEmitTime = now
                throttled.emit(value)
            }
        })
        holder.disposables.append(disposable)
        
        // Store holder to keep observer and disposable alive
        throttled._operatorHolder = holder
        
        return throttled
    }
    
    /// Skip until another stream emits
    public func skip<U>(until other: CameraEventStream<U>) -> CameraEventStream<Value> {
        let skipped = CameraEventStream<Value>()
        var canEmit = false
        let lockQueue = DispatchQueue(label: "com.camera.observable.skip")
        
        // Create holder to keep observer and disposables alive
        let holder = OperatorHolder()
        
        print("📡 [CameraObservable] ⏭️ Setting up skip(until:) operator")
        
        // Subscribe to 'other' stream to enable emission
        // Use sync to ensure canEmit is set before any frames arrive
        print("📡 [CameraObservable] 🔗 Subscribing skip(until:) observer to 'other' stream...")
        let otherDisposable = other.observe(on: holder.observer, observerBlock: { _ in
            print("📡 [CameraObservable] 🎯 skip(until:) received event from 'other' stream!")
            lockQueue.sync {
                canEmit = true
                print("📡 [CameraObservable] ✅ Skip condition met - can now emit values (canEmit = true)")
            }
        })
        holder.disposables.append(otherDisposable)
        print("📡 [CameraObservable] ✅ skip(until:) observer subscribed to 'other' stream (disposable retained)")
        
        // Subscribe to source stream
        let sourceDisposable = observe(on: holder.observer, observerBlock: { value in
            lockQueue.sync {
                if canEmit {
                    print("📡 [CameraObservable] ✅ Value passed skip filter - emitting")
                    skipped.emit(value)
                } else {
                    print("📡 [CameraObservable] ⏭️ Value skipped - waiting for condition (canEmit = false)")
                }
            }
        })
        holder.disposables.append(sourceDisposable)
        
        // Store holder in skipped stream to keep observer and disposables alive
        skipped._operatorHolder = holder
        
        return skipped
    }
    
    /// Take first N values
    public func take(_ count: Int) -> CameraEventStream<Value> {
        let taken = CameraEventStream<Value>()
        var takenCount = 0
        let lockQueue = DispatchQueue(label: "com.camera.observable.take")
        
        // Create holder to keep observer and disposable alive
        let holder = OperatorHolder()
        
        print("📡 [CameraObservable] 📥 Setting up take(\(count)) operator")
        let disposable = observe(on: holder.observer, observerBlock: { value in
            print("📡 [CameraObservable] 📥 take(\(count)) received value from source stream")
            lockQueue.sync {
                if takenCount < count {
                    takenCount += 1
                    print("📡 [CameraObservable] ✅ take(\(count)) emitting value #\(takenCount) to result stream")
                    taken.emit(value)
                    if takenCount >= count {
                        print("📡 [CameraObservable] ✅ take(\(count)) completed - reached limit")
                        // DON'T dispose observer here - keep it alive for potential future emissions
                        // The observer will be cleaned up when the stream is deallocated
                    }
                } else {
                    print("📡 [CameraObservable] ⏭️ take(\(count)) ignoring value - already reached limit")
                }
            }
        })
        holder.disposables.append(disposable)
        print("📡 [CameraObservable] ✅ take(\(count)) observer subscribed (disposable retained in holder)")
        
        // Keep holder alive - this ensures observer and disposable stay alive
        taken._operatorHolder = holder
        
        return taken
    }
    
    /// Take first value only
    public func takeFirst() -> CameraEventStream<Value> {
        return take(1)
    }
    
    /// FlatMapLatest operator
    public func flatMapLatest<U>(_ transform: @escaping (Value) -> CameraEventStream<U>) -> CameraEventStream<U> {
        let flatMapped = CameraEventStream<U>()
        let holder = OperatorHolder()
        
        // Use a class to hold mutable state for currentDisposable
        let state = FlatMapState()
        holder.additionalData = state
        
        let disposable = observe(on: holder.observer, observerBlock: { value in
            // Dispose previous subscription
            // Note: We dispose the subscription to the old stream, but the old stream itself
            // may still have pending async operations (like AI classification). Those operations
            // will complete, but their results won't be forwarded to flatMapped since we've
            // disposed the subscription. This is the expected behavior of flatMapLatest.
            // However, we keep the old stream alive briefly to allow async operations to complete
            // (they just won't forward to flatMapped, which is correct for flatMapLatest)
            state.currentDisposable?.dispose()
            
            // Subscribe to new stream
            let newStream = transform(value)
            // Keep old stream alive until new stream is set up (prevents premature deallocation)
            // This ensures async operations in oldStream (like AI classification) can complete
            let oldStream = state.currentStream
            state.currentStream = newStream // Keep new stream alive until next value or deallocation
            state.currentDisposable = newStream.observe(on: holder.observer, observerBlock: { mappedValue in
                flatMapped.emit(mappedValue)
            })
            // Old stream will be released when oldStream goes out of scope
            // This ensures async operations in oldStream can complete
        })
        holder.disposables.append(disposable)
        
        // Store holder to keep observer and disposables alive
        flatMapped._operatorHolder = holder
        
        return flatMapped
    }
    
    /// Do operator (side effects)
    public func `do`(onNext: @escaping (Value) -> Void) -> CameraEventStream<Value> {
        let doStream = CameraEventStream<Value>()
        let holder = OperatorHolder()
        
        let disposable = observe(on: holder.observer, observerBlock: { value in
            print("📡 [CameraObservable] 🔔 do(onNext:) received value")
            onNext(value)
            doStream.emit(value)
            print("📡 [CameraObservable] ✅ do(onNext:) emitted value to doStream")
        })
        holder.disposables.append(disposable)
        
        // Store holder to keep observer and disposable alive
        doStream._operatorHolder = holder
        
        return doStream
    }
    
    /// Catch errors (converts to empty stream)
    public func catchError(_ handler: @escaping (Error) -> Void) -> CameraEventStream<Value> {
        // For CameraObservable, we don't have error types, so this is a no-op
        // But kept for API compatibility
        return self
    }
    
    /// Observe on specific queue
    public func observe(on queue: DispatchQueue) -> CameraEventStream<Value> {
        let observed = CameraEventStream<Value>()
        let holder = OperatorHolder()
        
        let disposable = observe(on: holder.observer, queue: queue, observerBlock: { value in
            observed.emit(value)
        })
        holder.disposables.append(disposable)
        
        // Store holder to keep observer and disposable alive
        observed._operatorHolder = holder
        
        return observed
    }
    
    /// Subscribe (alias for observe)
    public func subscribe(onNext: @escaping (Value) -> Void) -> CameraDisposable {
        // Create a dummy observer object
        let observer = NSObject()
        return observe(on: observer, observerBlock: onNext)
    }
}


// MARK: - Amb Operator (race between streams)

extension CameraEventStream {
    /// Amb operator - emits from first stream that emits
    public static func amb<U>(_ streams: [CameraEventStream<U>]) -> CameraEventStream<U> {
        let ambed = CameraEventStream<U>()
        let holder = OperatorHolder()
        var hasEmitted = false
        let lockQueue = DispatchQueue(label: "com.camera.observable.amb")

        for stream in streams {
            let disposable = stream.observe(on: ambed, observerBlock: { value in
                lockQueue.async {
                    if !hasEmitted {
                        hasEmitted = true
                        ambed.emit(value)
                    }
                }
            })
            holder.disposables.append(disposable)
        }
        
        // Store holder to keep observers and disposables alive
        ambed._operatorHolder = holder

        return ambed
    }
}

// MARK: - ActivityIndicator (Replaces RxSwift ActivityIndicator)

public final class CameraActivityIndicator {
    public let isActive = CameraBehaviorStream<Bool>(false)
    
    public var asDriver: CameraDriver<Bool> {
        let driverStream = CameraEventStream<Bool>()
        
        isActive.observe(on: driverStream, observerBlock: { value in
            driverStream.emit(value)
        })
        
        return CameraDriver(source: driverStream)
    }
    
    public func trackActivity<Value>(_ stream: CameraEventStream<Value>) -> CameraEventStream<Value> {
        let tracked = CameraEventStream<Value>()
        
        isActive.accept(true)
        
        stream.observe(on: tracked, observerBlock: { value in
            self.isActive.accept(false)
            tracked.emit(value)
        })
        
        return tracked
    }
}

// MARK: - Delay Operator

extension CameraEventStream {
    /// Delay operator - delays emission by specified time interval
    public func delay(_ interval: TimeInterval, queue: DispatchQueue = .main) -> CameraEventStream<Value> {
        let delayed = CameraEventStream<Value>()
        
        observe(on: delayed, observerBlock: { value in
            queue.asyncAfter(deadline: .now() + interval) {
                delayed.emit(value)
            }
        })
        
        return delayed
    }
}

// MARK: - Empty Stream Helper

extension CameraEventStream {
    /// Create empty stream (never emits)
    public static func empty<U>() -> CameraEventStream<U> {
        return CameraEventStream<U>()
    }
}

// MARK: - Timer Helper Enhancement

extension CameraEventStream {
    /// Create timer that emits after delay (returns Void stream for compatibility)
    public static func timer(_ delay: TimeInterval, queue: DispatchQueue = .main) -> CameraEventStream<Void> {
        let timer = CameraEventStream<Void>()
        
        print("⏰ [CameraObservable] 🕐 Creating timer - delay: \(delay)s, queue: \(queue.label)")
        let startTime = Date()
        
        // Store timer reference to keep it alive
        timer._operatorHolder = NSObject()
        
        queue.asyncAfter(deadline: .now() + delay) {
            let actualDelay = Date().timeIntervalSince(startTime)
            print("⏰ [CameraObservable] ✅ Timer fired after \(String(format: "%.3f", actualDelay))s")
            
            // Check observer count synchronously and log details
            let observerInfo = timer.lockQueue.sync {
                let total = timer.observers.count
                let active = timer.observers.filter { $0.observer != nil }.count
                let nilCount = total - active
                return (total: total, active: active, nilCount: nilCount)
            }
            print("⏰ [CameraObservable] 📊 Timer stream observers: \(observerInfo.total) total, \(observerInfo.active) active, \(observerInfo.nilCount) nil")
            
            // Log each observer's state
            timer.lockQueue.sync {
                for (index, obs) in timer.observers.enumerated() {
                    let isNil = obs.observer == nil
                    let queueLabel = obs.queue?.label ?? "sync"
                    print("⏰ [CameraObservable] 📋 Observer #\(index + 1): nil=\(isNil), queue=\(queueLabel)")
                }
            }
            
            print("⏰ [CameraObservable] 📤 About to emit timer value...")
            timer.emit(())
            print("⏰ [CameraObservable] ✅ Timer value emitted")
            
            // Log observers after emit to debug
            timer.lockQueue.sync {
                print("⏰ [CameraObservable] 📊 After emit - observers: \(timer.observers.count) total")
                for (index, obs) in timer.observers.enumerated() {
                    let isNil = obs.observer == nil
                    let queueLabel = obs.queue?.label ?? "sync"
                    print("⏰ [CameraObservable] 📋 After emit - Observer #\(index + 1): nil=\(isNil), queue=\(queueLabel)")
                }
            }
        }
        
        return timer
    }
}
