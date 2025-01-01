import Foundation
import Cocoa
import AppKit
import ApplicationServices.HIServices


class Window: Equatable, Switchable {
    var application: Application
    var axWindow: AxWindow
    var id: CGWindowID
    var observer: AXObserver? = nil
    var globalOrder: Int // maintained by Windows
    var localOrder: Int
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
    
    static func == (lhs: Window, rhs: Window) -> Bool {
        return lhs.axWindow == rhs.axWindow
    }
    
    func getIcon() -> NSImage? {
        return self.application.getIcon()
    }
    
    func getTitle() -> String? {
        return self.title
    }
    
    init(application: Application, axWindow: AxWindow, globalOrder: Int, localOrder: Int) {
        self.application = application
        self.axWindow = axWindow
        self.globalOrder = globalOrder
        self.localOrder = localOrder
        self.id = try! axWindow.cgWindowId() ?? 0
        self.title = tryTitle()
        self.addObserver()
    }
    
    @MainActor
    static func join(app: Application, axWindow: AxWindow) -> Window {
        for window in app.windows {
            if window.axWindow == axWindow {
                return window
            }
        }
        let window = Window(application: app, axWindow: axWindow, globalOrder: Windows.shared.inner.count, localOrder: app.windows.count)
        Windows.shared.inner.append(window)
        app.windows.append(window)
        app.focusedWindow = window
        Applications.shared.peekApp(app: app)
        return window
    }
    
    @MainActor
    func peek() {
        Windows.shared.peekWindow(window: self)
        self.application.peekWindow(window: self)
        Applications.shared.peekApp(app: self.application)
    }
    
    @MainActor
    static func joinOrPeek(app: Application, axWindow: AxWindow) -> Window {
        if let focusedWindow = app.windows.first(where: { axWindow == $0.axWindow }) {
            focusedWindow.peek()
            return focusedWindow
        } else {
            return join(app: app, axWindow: axWindow)
        }
    }
    
    func tryTitle() -> String {
        let axTitle = try? axWindow.title()
        if let axTitle = axTitle, !axTitle.isEmpty {
            return axTitle
        }
        if let cgWindowId = (try? axWindow.cgWindowId()), let cgTitle = cgWindowId.title(), !cgTitle.isEmpty {
            return cgTitle
        }
        return application.runningApplication.localizedName ?? ""
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
                try self.axWindow.subscribeToNotification(observer, notification, ref)
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
            self.axWindow.focus()
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
            if let closeButton = try? self.axWindow.closeButton() {
                closeButton.performAction(action: kAXPressAction)
            }
        }
    }
    
    func handleEvent(notificationType: String, element: AXUIElement) throws {
        let element = AxWindow(element: element)
        switch notificationType {
        case kAXUIElementDestroyedNotification: try windowDestroyed(element: element)
        case kAXTitleChangedNotification: try windowTitleChanged(element: element)
        case kAXWindowMiniaturizedNotification: try windowMiniaturized(element: element)
        case kAXWindowDeminiaturizedNotification:try windowDeminiaturized(element: element)
        case kAXWindowMovedNotification: try windowMoved(element: element)
        default: break
        }
    }
    
    func windowDestroyed(element: AxWindow) throws {
        BackgroundWork.synchronizationQueue.taskRestricted {
            await MainActor.run {
                if self.application.focusedWindow == self {
                    self.application.focusedWindow = nil
                }
                self.application.removeWindow(window: self)
                Windows.shared.removeWindow(axWindow: element)
            }
        }
    }
    
    func windowTitleChanged(element: AxWindow) throws {
        title = tryTitle()
    }
    
    func windowMiniaturized(element: AxWindow) throws {
        isMinimized = true
    }
    
    func windowDeminiaturized(element: AxWindow) throws {
        isMinimized = false
    }
    
    func windowMoved(element: AxWindow) throws {
    }
}

