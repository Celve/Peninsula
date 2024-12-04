import Foundation
import AppKit

func isNotXpc(_ app: NSRunningApplication) -> Bool {
    // these private APIs are more reliable than Bundle.init? as it can return nil (e.g. for com.apple.dock.etci)
    var psn = ProcessSerialNumber()
    GetProcessForPID(app.processIdentifier, &psn)
    var info = ProcessInfoRec()
    GetProcessInformation(&psn, &info)
    return String(info.processType) != "XPC!"
}


class Applications: ObservableObject {
    static let shared = Applications()
    
    @Published var inner: [Application] = []
    var timer: DispatchSourceTimer? = nil
    
    init() {
        WorkspaceEvents.observeRunningApplications()
        addInitials()
        refreshBadges()
        autoRefresh()
    }
    
    func addInitials() {
        let runningApplications = NSWorkspace.shared.runningApplications
        runningApplications.forEach {
            if !$0.processIdentifier.isZombie() && isNotXpc($0) {
                if let name = $0.localizedName, name != "Peninsula" {
                    inner.append(Application(runningApplication: $0))
                }
            }
        }
    }
    
    func autoRefresh() {
        timer = DispatchSource.makeTimerSource(queue: BackgroundWork.axCallsQueue)
        timer?.schedule(deadline: .now(), repeating: .seconds(1))
        timer?.setEventHandler {
            self.refreshBadges()
        }
        timer?.resume()
    }
    
    func refreshBadges() {
        retryAxCallUntilTimeout {
            if let dockApp = (self.inner.first { $0.runningApplication.bundleIdentifier == "com.apple.dock" }),
               let axList = try dockApp.axApplication?.children()?.first { try $0.role() == kAXListRole },
            let axAppDockItem = (try axList.children()?.filter { try $0.subrole() == kAXApplicationDockItemSubrole && ($0.appIsRunning() ?? false) }) {
                let axAppDockItemUrlAndLabel = try axAppDockItem.map { try ($0.attribute(kAXURLAttribute, URL.self), $0.attribute(kAXStatusLabelAttribute, String.self)) }
                DispatchQueue.main.async {
                    axAppDockItemUrlAndLabel.forEach { url, label in
                        let app = self.inner.first { $0.runningApplication.bundleURL == url  }
                        app?.label = label
                    }
                }
            }
        }
    }
    
    func isActualApplication(_ app: NSRunningApplication) -> Bool {
        // an app can start with .activationPolicy == .prohibited, then transition to != .prohibited later
        // an app can be both activationPolicy == .accessory and XPC (e.g. com.apple.dock.etci)
        return (isNotXpc(app)) && !app.processIdentifier.isZombie()
    }
    
    func addApp(_ runningApps: [NSRunningApplication]) {
        runningApps.forEach {
            if isActualApplication($0) {
                self.inner.append(Application(runningApplication: $0))
            }
        }
    }
    
    func removeApp(_ runningApps: [NSRunningApplication]) {
        var windowsOnTheLeftOfFocusedWindow = 0
        for runningApp in runningApps {
            // comparing pid here can fail here, as it can be already nil; we use isEqual here to avoid the issue
            self.inner.removeAll { $0.runningApplication.isEqual(runningApp) }
            Windows.shared.inner.removeAll { $0.application.runningApplication.isEqual(runningApp) }
        }
    }
}

class WorkspaceEvents {
    private static var appsObserver: NSKeyValueObservation!
    private static var previousValueOfRunningApps: Set<NSRunningApplication>!
    
    static func observeRunningApplications() {
        previousValueOfRunningApps = Set(NSWorkspace.shared.runningApplications)
        appsObserver = NSWorkspace.shared.observe(\.runningApplications, options: [.old, .new], changeHandler: observerCallback)
    }
    
    static func observerCallback<A>(_ application: NSWorkspace, _ change: NSKeyValueObservedChange<A>) {
        let workspaceApps = Set(NSWorkspace.shared.runningApplications)
        // TODO: symmetricDifference has bad performance
        let diff = Array(workspaceApps.symmetricDifference(previousValueOfRunningApps))
        if change.kind == .insertion {
            Applications.shared.addApp(diff)
        } else if change.kind == .removal {
            Applications.shared.removeApp(diff)
        }
        previousValueOfRunningApps = workspaceApps
    }
}
