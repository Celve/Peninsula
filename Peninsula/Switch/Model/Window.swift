import Foundation
import Cocoa
import AppKit
import ApplicationServices.HIServices


final class Window: Element, Switchable {
    typealias C = Windows
    var axElement: AXUIElement
    var colls: [(Windows, Int)] = []
    var covs: [any Element]
    
    var application: App
    var id: CGWindowID
    var observer: AXObserver? = nil
    var title: String!
    var isHidden: Bool { get { application.isHidden } }
    var label: String? { get { application.label } }
    var isMinimized: Bool = false
    var log: String? = nil
    
    static let notifications = [
        kAXUIElementDestroyedNotification,
        kAXTitleChangedNotification,
        kAXWindowMiniaturizedNotification,
        kAXWindowDeminiaturizedNotification,
        kAXWindowMovedNotification,
        kAXWindowResizedNotification,
    ]
    
    func getIcon() -> NSImage? {
        return self.application.getIcon()
    }
    
    func getTitle() -> String? {
        return self.title
    }
    
    init(app: App, axWindow: AXUIElement) {
        self.axElement = axWindow
        self.application = app
        self.covs = [app]
        self.id = try! axWindow.cgWindowId() ?? 0
        self.title = tryTitle()
        self.addObserver()
        self.add(coll: Windows.shared)
        self.add(coll: app.windows)
        for cov in self.covs {
            cov.peek()
        }
    }
    
    func tryTitle() -> String {
        let axTitle = try? axElement.title()
        if let axTitle = axTitle, !axTitle.isEmpty {
            return axTitle
        }
        if let cgWindowId = (try? axElement.cgWindowId()), let cgTitle = cgWindowId.title(), !cgTitle.isEmpty {
            return cgTitle
        }
        return application.nsApp.localizedName ?? ""
    }
    
    func addObserver() {
        let callback: @convention(c) (AXObserver, AXUIElement, CFString, UnsafeMutableRawPointer?) -> Void = { observer, element, notification, ref in
            let this = Unmanaged<Window>.fromOpaque(ref!).takeUnretainedValue()
            retryAxCallUntilTimeout { try this.handleEvent(notificationType: notification as String, element: element) }
        }
        
        AXObserverCreate(application.pid, callback, &observer)
        guard let observer = observer else { return }
        for notification in Window.notifications {
            retryAxCallUntilTimeout { [weak self] in
                guard let self = self else { return }
                let ref = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
                try self.axElement.subscribeToNotification(observer, notification, ref)
            }
        }
        CFRunLoopAddSource(BackgroundWork.accessibilityEventsThread.runLoop, AXObserverGetRunLoopSource(observer), .defaultMode)
    }
    
    func focus() {
        BackgroundWork.commandQueue.asyncRestricted { [weak self] in
            guard let self = self else { return }
            var psn = ProcessSerialNumber()
            GetProcessForPID(self.application.pid, &psn)
            _SLPSSetFrontProcessWithOptions(&psn, self.id, SLPSMode.userGenerated.rawValue)
            self.makeKeyWindow(psn)
            self.axElement.focus()
        }
    }
    
    func makeKeyWindow(_ psn: ProcessSerialNumber) -> Void {
        var psn_ = psn
        var bytes1 = [UInt8](repeating: 0, count: 0xf8)
        bytes1[0x04] = 0xF8
        bytes1[0x08] = 0x01
        bytes1[0x3a] = 0x10
        var bytes2 = [UInt8](repeating: 0, count: 0xf8)
        bytes2[0x04] = 0xF8
        bytes2[0x08] = 0x02
        bytes2[0x3a] = 0x10
        memcpy(&bytes1[0x3c], &id, MemoryLayout<UInt32>.size)
        memset(&bytes1[0x20], 0xFF, 0x10)
        memcpy(&bytes2[0x3c], &id, MemoryLayout<UInt32>.size)
        memset(&bytes2[0x20], 0xFF, 0x10)
        [bytes1, bytes2].forEach { bytes in
            _ = bytes.withUnsafeBufferPointer() { pointer in
                SLPSPostEventRecordTo(&psn_, &UnsafeMutablePointer(mutating: pointer.baseAddress)!.pointee)
            }
        }
    }
    
    func close() {
        BackgroundWork.axCallsQueue.async { [weak self] in
            guard let self = self else { return }
//            if self.isFullscreen {
//                self.axUiElement.setAttribute(kAXFullscreenAttribute, false)
//            }
            if let closeButton = try? self.axElement.closeButton() {
                closeButton.performAction(action: kAXPressAction)
            }
        }
    }
    
    func handleEvent(notificationType: String, element: AXUIElement) throws {
        switch notificationType {
        case kAXUIElementDestroyedNotification: try windowDestroyed(element: element)
        case kAXTitleChangedNotification: try windowTitleChanged(element: element)
        case kAXWindowMiniaturizedNotification: try windowMiniaturized(element: element)
        case kAXWindowDeminiaturizedNotification:try windowDeminiaturized(element: element)
        case kAXWindowMovedNotification: try windowMoved(element: element)
        default: break
        }
    }
    
    func windowDestroyed(element: AXUIElement) throws {
        BackgroundWork.synchronizationQueue.taskRestricted {
            await MainActor.run {
                self.destroy()
            }
        }
    }
    
    func windowTitleChanged(element: AXUIElement) throws {
        title = tryTitle()
    }
    
    func windowMiniaturized(element: AXUIElement) throws {
        isMinimized = true
    }
    
    func windowDeminiaturized(element: AXUIElement) throws {
        isMinimized = false
    }
    
    func windowMoved(element: AXUIElement) throws {
    }
}

