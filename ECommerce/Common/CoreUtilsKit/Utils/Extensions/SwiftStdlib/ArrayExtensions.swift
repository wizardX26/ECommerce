import Foundation

public extension Array {
    subscript (safe index: Int) -> Element? {
        get {
            return (0 <= index && index < count) ? self[index] : nil
        }
        set (value) {
            if value == nil {
                return
            }

            if !(count > index) {
                return
            }

            self[index] = value!
        }
    }
}

extension Array where Element: Equatable {
    mutating public func remove(object: Element) {
        guard let index = firstIndex(of: object) else {return}
        remove(at: index)
    }
}
