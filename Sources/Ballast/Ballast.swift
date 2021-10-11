import Foundation

@propertyWrapper
public class Ballast<Value: AnyObject> {
    
    public enum RetentionPolicy {
        case unretained
        case manualRelease
        case notification(Notification.Name)
        case disuse(DispatchTimeInterval, DispatchQueue)
    }
    
    public var wrappedValue: Value {
        get {
            defer {
                switch policy {
                case .manualRelease, .notification(_):
                    break
                case .disuse(let interval, let queue):
                    deletionWorkItem?.cancel()
                    deletionWorkItem = DispatchWorkItem { [weak self] in
                        self?.strongValue = nil
                    }
                    if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6,  *) {
                        queue.asyncAfter(deadline: .now().advanced(by: interval), execute: deletionWorkItem!)
                    } else {
                        queue.asyncAfter(deadline: .now() + interval, execute: deletionWorkItem!)
                    }
                    break
                case .unretained:
                    strongValue = nil
                }
            }
            if weakValue == nil {
                strongValue = builder()
                weakValue = strongValue
            }
            guard let v = weakValue else { fatalError() }
            return v
        }
        set {
            switch policy {
            case .unretained:
                weakValue = newValue
                strongValue = nil
            case .manualRelease, .notification(_):
                weakValue = newValue
                strongValue = newValue
            case .disuse(let interval, let queue):
                weakValue = newValue
                strongValue = newValue
                
                deletionWorkItem?.cancel()
                deletionWorkItem = DispatchWorkItem { [weak self] in
                    self?.strongValue = nil
                }
                if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6,  *) {
                    queue.asyncAfter(deadline: .now().advanced(by: interval), execute: deletionWorkItem!)
                } else {
                    queue.asyncAfter(deadline: .now() + interval, execute: deletionWorkItem!)
                }
                break
            }
        }
    }
    
    /// Removes strong ownership over the `wrappedValue`, possibly causing the
    /// value object to be released. If other strong owners of the object are keeping it
    /// from being released, the property wrapper will continue to vend the original value.
    ///
    /// Has no effect when policy is `.unretained`
    public func jettison() {
        // TODO: Should a jettison event that doesn't result in a release re-strongify the value? If so when? On first read after jettison?
        strongValue = nil
    }
    
    private weak var weakValue: Value?
    private var strongValue: Value?
    
    private let builder: () -> Value
    private let policy: RetentionPolicy
    
    private var deletionWorkItem: DispatchWorkItem?
    
    public init(_ builder: @escaping @autoclosure ()->Value, policy: RetentionPolicy = .unretained) {
        self.builder = builder
        self.policy = policy
        
        if case .notification(let name) = policy {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [weak self] notification in
                self?.jettison()
            }
        }
    }
}
