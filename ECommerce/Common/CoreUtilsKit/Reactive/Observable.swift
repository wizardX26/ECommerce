import Foundation

public final class Observable<Value> {
    
    struct Observer<T> {
        weak var observer: AnyObject?
        let block: (T) -> Void
    }
    
    private var observers = [Observer<Value>]()
    
    var value: Value {
        didSet { notifyObservers() }
    }
    
    init(_ value: Value) {
        self.value = value
    }
    
    func observe(on observer: AnyObject, observerBlock: @escaping (Value) -> Void) {
        observers.append(Observer(observer: observer, block: observerBlock))
        observerBlock(self.value)
    }
    
    func remove(observer: AnyObject) {
        observers = observers.filter { $0.observer !== observer }
    }
    
    private func notifyObservers() {
        /*
         Clean up deallocated observers
         This is to prevent memory leaks,
         can cause crashes if not cleaned up.
         */
        observers = observers.filter { $0.observer != nil }
        
        /// Notify active observers
        for observer in observers {
            observer.block(self.value)
        }
    }
}
