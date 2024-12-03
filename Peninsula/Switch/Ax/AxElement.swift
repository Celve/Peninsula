import ApplicationServices.HIServices.AXError
import AppKit
import Foundation

enum AxError: Error {
    case runtimeError
}

func axCallWhichCanThrow<T>(_ result: AXError, _ successValue: inout T) throws -> T? {
    switch result {
        case .success: return successValue
        // .cannotComplete can happen if the app is unresponsive; we throw in that case to retry until the call succeeds
        case .cannotComplete: throw AxError.runtimeError
        // for other errors it's pointless to retry
        default: return nil
    }
}

class AxElement: Equatable  {
    var element: AXUIElement
    
    init(element: AXUIElement) {
        self.element = element
    }
    
    static func == (lhs: AxElement, rhs: AxElement) -> Bool {
        return lhs.element == rhs.element
    }

    func attribute<T>(_ key: String, _ _: T.Type) throws -> T? {
        var value: AnyObject?
        return try axCallWhichCanThrow(AXUIElementCopyAttributeValue(element, key as CFString, &value), &value) as? T
    }
    
    func value<T>(_ key: String, _ target: T, _ type: AXValueType) throws -> T? {
        if let a = try attribute(key, AXValue.self) {
            var value = target
            AXValueGetValue(a, type, &value)
            return value
        }
        return nil
    }
    
    func pid() throws -> pid_t? {
        var pid = pid_t(0)
        return try axCallWhichCanThrow(AXUIElementGetPid(element, &pid), &pid)
    }
    
    func title() throws -> String? {
        return try attribute(kAXTitleAttribute, String.self)
    }
    
    func role() throws -> String? {
        return try attribute(kAXRoleAttribute, String.self)
    }
    
    func subrole() throws -> String? {
        return try attribute(kAXSubroleAttribute, String.self)
    }
    
    func appIsRunning() throws -> Bool? {
        return try attribute(kAXIsApplicationRunningAttribute, Bool.self)
    }
    
    func subscribeToNotification(_ axObserver: AXObserver, _ notification: String, _ ref: UnsafeMutableRawPointer?) throws {
        let result = AXObserverAddNotification(axObserver, element, notification as CFString, ref)
        if result != .success && result != .notificationAlreadyRegistered && result != .notificationUnsupported && result != .notImplemented {
            throw AxError.runtimeError
        }
    }
    
    func toAxWindow() -> AxWindow {
        AxWindow(element: element)
    }
    
    func toAxApplication() -> AxApplication {
        AxApplication(element: element)
    }
    
    func performAction(action: String) {
        AXUIElementPerformAction(element, action as CFString)
    }
    
    func children() throws -> [AxElement]? {
        let result: [AXUIElement]? = try attribute(kAXChildrenAttribute, [AXUIElement].self)
        return result?.map { AxElement(element: $0) } 
    }
}

extension AxElement: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(element)
    }
}
