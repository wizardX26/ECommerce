import Foundation

/// Abstraction over DispatchQueue
/// Used to easily mock main and background queues in tests
protocol DispatchQueueType {
    
    /// Execute work asynchronously
    func async(
        execute work: @escaping () -> Void
    )
    
    /// Execute work asynchronously after a delay
    /// - Parameter delay: Delay in seconds
    func asyncAfter(
        delay: TimeInterval,
        execute work: @escaping () -> Void
    )
}

// MARK: - Production implementation

extension DispatchQueue: DispatchQueueType {
    
    func async(
        execute work: @escaping () -> Void
    ) {
        self.async(
            group: nil,
            qos: .unspecified,
            flags: [],
            execute: work
        )
    }
    
    func asyncAfter(
        delay: TimeInterval,
        execute work: @escaping () -> Void
    ) {
        self.asyncAfter(
            deadline: .now() + delay,
            qos: .unspecified,
            flags: [],
            execute: work
        )
    }
}
/*`GCD` has 2 overload
 func asyncAfter(deadline: DispatchTime, execute: @escaping () -> Void)
 func asyncAfter(deadline: DispatchTime, qos: DispatchQoS, flags: DispatchWorkItemFlags, execute: @escaping () -> Void)
 */

