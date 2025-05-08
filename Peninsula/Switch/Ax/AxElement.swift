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

extension AXUIElement {
    func attribute<T>(_ key: String, _ _: T.Type) throws -> T? {
        var value: AnyObject?
        return try axCallWhichCanThrow(AXUIElementCopyAttributeValue(self, key as CFString, &value), &value) as? T
    }
    
    func attributes<T>(_ key: String, _ _: T.Type) throws -> [T]? {
        // maybe useless compared to attribute
        var count: CFIndex = 0
        _ = try axCallWhichCanThrow(AXUIElementGetAttributeValueCount(self, key as CFString, &count), &count)
        var value: CFArray?
        return try axCallWhichCanThrow(AXUIElementCopyAttributeValues(self, key as CFString, 0, count, &value), &value) as? [T]
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
        return try axCallWhichCanThrow(AXUIElementGetPid(self, &pid), &pid)
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
    
    func identifier() throws -> String? {
        return try attribute(kAXIdentifierAttribute, String.self)
    }
    
    func appIsRunning() throws -> Bool? {
        return try attribute(kAXIsApplicationRunningAttribute, Bool.self)
    }
    
    func subscribeToNotification(_ axObserver: AXObserver, _ notification: String, _ ref: UnsafeMutableRawPointer?) throws {
        let result = AXObserverAddNotification(axObserver, self, notification as CFString, ref)
        if result != .success && result != .notificationAlreadyRegistered && result != .notificationUnsupported && result != .notImplemented {
            throw AxError.runtimeError
        }
    }
    
    func performAction(action: String) {
        AXUIElementPerformAction(self, action as CFString)
    }
    
    func setAttribute(_ key: String, _ value: Any) {
        AXUIElementSetAttributeValue(self, key as CFString, value as CFTypeRef)
    }
    
    func children() throws -> [AXUIElement]? {
        let result: [AXUIElement]? = try attribute(kAXChildrenAttribute, [AXUIElement].self)
        return result
    }
    
    func parent() throws -> AXUIElement? {
        return try attribute(kAXParentAttribute, AXUIElement.self)
    }
    
    func rootParent() throws -> AXUIElement? {
        var current = self
        while let parent = try current.parent() {
            current = parent
        }
        return current
    }

    func secondRootParent() throws -> AXUIElement? {
        var current = self, last = self
        while let parent = try current.parent() {
            last = current
            current = parent
        }
        return last
    }
    
    func closeButton() throws -> AXUIElement? {
        return try attribute(kAXCloseButtonAttribute, AXUIElement.self)
    }
}

