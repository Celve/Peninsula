import Foundation
import ApplicationServices.HIServices.AXNotificationConstants
import AppKit

class Application: Switchable {
    var pid: pid_t
    var icon: NSImage?
    var runningApplication: NSRunningApplication
    var axApplication: AxApplication?
    var observer: AXObserver? = nil
    var focusedWindow: Window? = nil
    var windows: [Window] = []
    var isHidden: Bool = false
    var label: String? = nil
    var name: String? = nil
    var bundleId: String? = nil
    var globalOrder: Int // maintained by Applications
    
    static let notifications = [
        kAXApplicationActivatedNotification,
        kAXMainWindowChangedNotification,
        kAXFocusedWindowChangedNotification,
        kAXWindowCreatedNotification,
        kAXApplicationHiddenNotification,
        kAXApplicationShownNotification,
    ]
    
    init(runningApplication: NSRunningApplication, globalOrder: Int) {
        self.pid = runningApplication.processIdentifier
        self.runningApplication = runningApplication
        self.icon = runningApplication.icon
        self.name = runningApplication.localizedName
        self.bundleId = runningApplication.bundleIdentifier
        self.globalOrder = globalOrder
        self.addObserver()
        updateWindows()
    }
    
    func getIcon() -> NSImage? {
        return icon
    }
    
    func getTitle() -> String? {
        return name
    }
    
    func focus() {
        if focusedWindow != nil {
            focusedWindow?.focus()
        } else if windows.count > 0 {
            windows[0].focus()
        }
    }
    
    func close() {
        
    }
    
    @MainActor
    func joinWindow(axWindow: AxWindow) {
        _ = Window.join(app: self, axWindow: axWindow)
    }

    func updateWindows() {
        retryAxCallUntilTimeout(timeoutInSeconds: 5) { [weak self] in
            guard let self = self else { return }
            guard let axApplication = self.axApplication else { return }
            if let axWindows = try axApplication.windows(), axWindows.count > 0 {
                // bug in macOS: sometimes the OS returns multiple duplicate windows (e.g. Mail.app starting at login)
                axWindows.forEach { axWindow in
                    if axWindow.isActual(runningApp: self.runningApplication) {
                        BackgroundWork.synchronizationQueue.taskRestricted {
                            await MainActor.run {
                                self.joinWindow(axWindow: axWindow)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func addObserver() {
        if runningApplication.activationPolicy != .prohibited && axApplication == nil {
            axApplication = AxApplication(element: AXUIElementCreateApplication(pid))
            let callback: @convention(c) (AXObserver, AXUIElement, CFString, UnsafeMutableRawPointer?) -> Void = { observer, element, notification, ref in
                let this = Unmanaged<Application>.fromOpaque(ref!).takeUnretainedValue()
                retryAxCallUntilTimeout { try this.handleEvent(notificationType: notification as String, element: element) }
            }
            
            AXObserverCreate(pid, callback, &observer)
            guard let observer = observer else { return }
            for notification in Application.notifications {
                retryAxCallUntilTimeout { [weak self] in
                    guard let self = self else { return }
                    let ref = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
                    try self.axApplication?.subscribeToNotification(observer, notification, ref)
                }
            }
            CFRunLoopAddSource(BackgroundWork.accessibilityEventsThread.runLoop, AXObserverGetRunLoopSource(observer), .defaultMode)
        }
    }
    
    func handleEvent(notificationType: String, element: AXUIElement) throws {
        switch notificationType {
        case kAXApplicationActivatedNotification: try applicationActivated(element: AxApplication(element: element))
        case kAXMainWindowChangedNotification, kAXFocusedWindowChangedNotification: try focusedWindowChanged(element: AxWindow(element: element))
        case kAXWindowCreatedNotification: try windowCreated(element: AxWindow(element: element))
        case kAXApplicationHiddenNotification: try applicationHidden(element: AxApplication(element: element))
        case kAXApplicationShownNotification: try applicationShown(element: AxApplication(element: element))
        default: return
        }
    }
    
    func applicationActivated(element: AxApplication) throws {
        guard let axFocusedWindow = try element.focusedWindow() else { return }
        if axFocusedWindow.isActual(runningApp: self.runningApplication) {
            BackgroundWork.synchronizationQueue.taskRestricted {
                await MainActor.run {
                    _ = Window.joinOrPeek(app: self, axWindow: axFocusedWindow)
                }
            }
        }
    }
    
    func focusedWindowChanged(element: AxWindow) throws {
        if element.isActual(runningApp: self.runningApplication) {
            BackgroundWork.synchronizationQueue.taskRestricted {
                await MainActor.run {
                    _ = Window.joinOrPeek(app: self, axWindow: element)
                }
            }
        }
    }
    
    @MainActor
    func removeWindow(window: Window) {
        guard let index = windows.firstIndex(where: { window == $0 }) else { return }
        windows.remove(at: index)
    }
    
    @MainActor
    func peekWindow(window: Window) {
        for other in windows {
            if other.localOrder > window.localOrder {
                other.localOrder -= 1
            }
        }
        window.localOrder = windows.count - 1
        sort()
    }
    
    func windowCreated(element: AxWindow) throws {
        BackgroundWork.synchronizationQueue.taskRestricted {
            await MainActor.run {
                if element.isActual(runningApp: self.runningApplication) {
                    _ = Window.joinOrPeek(app: self, axWindow: element)
                }
            }
        }
    }
    
    func applicationHidden(element: AxApplication) throws {
        isHidden = true
    }
    
    func applicationShown(element: AxApplication) throws {
        isHidden = false
    }
    
    func sort() {
        windows.sort {
            return $0.localOrder > $1.localOrder
        }
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
