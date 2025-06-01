import Foundation
import ApplicationServices.HIServices.AXNotificationConstants
import AppKit

class App: Element, Switchable {
    typealias M = App
    typealias C = Apps
    var axElement: AXUIElement
    var covs: [any Element] = []
    var colls: [Apps] = []

    var windows = Windows()
    var pid: pid_t
    var icon: NSImage
    var nsApp: NSRunningApplication
    var observer = AppObserver()
    var isHidden: Bool = false
    var label: String? = nil
    var name: String! {
        didSet {
            matchableString = MatchableString(string: name.lowercased())
        }
    }
    var bundleId: String
    
    var quitRequested: Bool = false

    var matchableString: MatchableString
    
    init(nsApp: NSRunningApplication) {
        self.pid = nsApp.processIdentifier
        self.nsApp = nsApp
        self.icon = nsApp.icon ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)!
        self.name = nsApp.localizedName ?? ""
        self.matchableString = MatchableString(string: name.lowercased())
        self.bundleId = nsApp.bundleIdentifier ?? ""
        self.axElement = AXUIElementCreateApplication(pid)
        BackgroundWork.synchronizationQueue.taskRestricted {
            await MainActor.run {
                self.add(coll: Apps.shared)
            }
        }
        self.observer.app = self
        self.observer.addObserver()
        self.observer.updateWindows()
    }
    
    func getIcon() -> NSImage? {
        return icon
    }
    
    func getTitle() -> String? {
        return name
    }

    func getMatchableString() -> MatchableString {
        return matchableString
    }
    
    func focus() {
        if windows.coll.count > 0 {
            windows.coll[0].focus()
        }
    }
    
    func hide() {
        if nsApp.isHidden {
            nsApp.unhide()
        } else {
            nsApp.hide()
        }
    }
    
    func minimize() {
        hide()
    }
    
    func canBeQuit() -> Bool {
        return bundleIdentifier != "com.apple.finder"
    }

    func quit() {
        if !canBeQuit() {
            NSSound.beep()
            return
        }
        if quitRequested {
            nsApp.forceTerminate()
        } else {
            nsApp.terminate()
            quitRequested = true
        }
    }

    @MainActor
    func destroy() {
        // First destroy all windows
        for window in windows.coll {
            window.destroy()
        }
        
        // Then destroy self
        (self as any Element).destroy()
    }

    func close() {
        quit()
    }
}

class AppObserver {
    weak var app: App? = nil
    var observer: AXObserver? = nil
    
    static let notifications = [
        kAXApplicationActivatedNotification,
        kAXMainWindowChangedNotification,
        kAXFocusedWindowChangedNotification,
        kAXWindowCreatedNotification,
        kAXApplicationHiddenNotification,
        kAXApplicationShownNotification,
    ]
       
    func updateWindows() {
        retryAxCallUntilTimeout(timeoutInSeconds: 5) { [weak self] in
            guard let self = self, let app = self.app else { return }
            let axApplication = app.axElement
            if let axWindows = try axApplication.windows(), axWindows.count > 0 {
                // bug in macOS: sometimes the OS returns multiple duplicate windows (e.g. Mail.app starting at login)
                axWindows.forEach { axWindow in
                    if axWindow.isActual(runningApp: app.nsApp) {
                        BackgroundWork.synchronizationQueue.taskRestricted {
                            await MainActor.run {
                                _ = Window(app: app, axWindow: axWindow)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func addObserver() {
        guard let app = self.app else { return }
        if app.nsApp.activationPolicy != .prohibited {
            let callback: @convention(c) (AXObserver, AXUIElement, CFString, UnsafeMutableRawPointer?) -> Void = { observer, element, notification, ref in
                let this = Unmanaged<AppObserver>.fromOpaque(ref!).takeUnretainedValue()
                retryAxCallUntilTimeout { try this.handleEvent(notificationType: notification as String, element: element) }
            }
            
            AXObserverCreate(app.pid, callback, &observer)
            guard let observer = observer else { return }
            for notification in Self.notifications {
                retryAxCallUntilTimeout { [weak self] in
                    guard let self = self, let app = self.app else { return }
                    let ref = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
                    try app.axElement.subscribeToNotification(observer, notification, ref)
                }
            }
            CFRunLoopAddSource(BackgroundWork.accessibilityEventsThread.runLoop, AXObserverGetRunLoopSource(observer), .defaultMode)
        }
    }
    
    func handleEvent(notificationType: String, element: AXUIElement) throws {
        switch notificationType {
        case kAXApplicationActivatedNotification: try applicationActivated(element: element)
        case kAXMainWindowChangedNotification, kAXFocusedWindowChangedNotification: try focusedWindowChanged(element: element)
        case kAXWindowCreatedNotification: try windowCreated(element: element)
        case kAXApplicationHiddenNotification: try applicationHidden(element: element)
        case kAXApplicationShownNotification: try applicationShown(element: element)
        default: return
        }
    }
    
    func applicationActivated(element: AXUIElement) throws {
        guard let axFocusedWindow = try element.focusedWindow(), let app = self.app else { return }
        if axFocusedWindow.isActual(runningApp: app.nsApp) {
            BackgroundWork.synchronizationQueue.taskRestricted {
                await MainActor.run {
                    if let window = app.windows.fetch(axElement: axFocusedWindow) {
                        window.peek()
                    } else {
                        _ = Window(app: app, axWindow: axFocusedWindow)
                    }
                }
            }
        }
    }
    
    func focusedWindowChanged(element: AXUIElement) throws {
        if let app = app, element.isActual(runningApp: app.nsApp) {
            BackgroundWork.synchronizationQueue.taskRestricted {
                await MainActor.run {
                    if let window = app.windows.fetch(axElement: element) {
                        window.peek()
                    } else {
                        _ = Window(app: app, axWindow: element)
                    }
                }
            }
        }
    }
    
    func windowCreated(element: AXUIElement) throws {
        guard let app = self.app else { return }
        BackgroundWork.synchronizationQueue.taskRestricted {
            await MainActor.run {
                if element.isActual(runningApp: app.nsApp) {
                    _ = Window(app: app, axWindow: element)
                }
            }
        }
    }
    
    func applicationHidden(element: AXUIElement) throws {
        guard let app = app else { return }
        app.isHidden = true
    }
    
    func applicationShown(element: AXUIElement) throws {
        guard let app = app else { return }
        app.isHidden = false
    }
    
    func close() {
        
    }
}

extension pid_t {
    func isZombie() -> Bool {
        var kinfo = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, self]
        sysctl(&mib, u_int(mib.count), &kinfo, &size, nil, 0)
        _ = withUnsafePointer(to: &kinfo.kp_proc.p_comm) {
            String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
        }
        return kinfo.kp_proc.p_stat == SZOMB
    }
}
