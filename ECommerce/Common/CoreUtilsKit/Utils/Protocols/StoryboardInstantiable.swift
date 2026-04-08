import UIKit

protocol StoryboardInstantiable: NSObjectProtocol {
    associatedtype T
    static var storyboardName: String { get }
    static var storyboardIdentifier: String { get }
    
    static func instantiateViewController(_ bundle: Bundle?) -> T
}

extension StoryboardInstantiable where Self: UIViewController {
    static var storyboardName: String {
        return NSStringFromClass(Self.self).components(separatedBy: ".").last!
    }
    static var storyboardIdentifier: String {
        return storyboardName
    }
    
    static func instantiateViewController(_ bundle: Bundle? = nil) -> Self {
        let storyboardName = Self.storyboardName
        let identifier = storyboardIdentifier
        let storyboard = UIStoryboard(name: storyboardName, bundle: bundle)
        
        guard let vc = storyboard.instantiateViewController(withIdentifier: identifier) as? Self else {
            fatalError("Cannot instantiate view controller \(Self.self) with identifier \(identifier) from storyboard with name \(storyboardName)")
        }
        return vc
    }
}
