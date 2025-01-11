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


final class Apps: Collection, ObservableObject {
    var id = UUID()
    @Published var coll: [App] = [] {
        didSet {
            useableInner = coll.filter {  Dock.shared.apps.contains($0.name) }
        }
    }
    @Published var useableInner: [App] = []
    
    static let shared = Apps()
    
    var timer: DispatchSourceTimer? = nil
    
    init() {
        WorkspaceEvents.observeRunningApplications()
        addInitials()
        refreshBadges()
        autoRefresh()
    }
    
    func addInitials() {
        let runningApplications = NSWorkspace.shared.runningApplications
        BackgroundWork.synchronizationQueue.taskRestricted {
            await MainActor.run {
                for runningApp in runningApplications {
                    _ = App(nsApp: runningApp)
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
            if let dockApp = (self.coll.first { $0.nsApp.bundleIdentifier == "com.apple.dock" }),
               let axList = try dockApp.axElement.children()?.first { try $0.role() == kAXListRole },
            let axAppDockItem = (try axList.children()?.filter { try $0.subrole() == kAXApplicationDockItemSubrole && ($0.appIsRunning() ?? false) }) {
                let axAppDockItemUrlAndLabel = try axAppDockItem.map { try ($0.attribute(kAXURLAttribute, URL.self), $0.attribute(kAXStatusLabelAttribute, String.self)) }
                DispatchQueue.main.async {
                    axAppDockItemUrlAndLabel.forEach { url, label in
                        let app = self.coll.first { $0.nsApp.bundleURL == url  }
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
            Dock.shared.refresh()
            BackgroundWork.synchronizationQueue.taskRestricted {
                await MainActor.run {
                    for app in diff {
                        _ = App(nsApp: app)
                    }
                }
            }
        } else if change.kind == .removal {
            Dock.shared.refresh()
            BackgroundWork.synchronizationQueue.taskRestricted {
                await MainActor.run {
                    let apps = Apps.shared
                    for runningApp in diff {
                        if let appId = apps.coll.firstIndex(where: { $0.nsApp == runningApp }) {
                            let app = apps.coll[appId]
                            app.destroy()
                        }
                    }
                }
            }
        }
        previousValueOfRunningApps = workspaceApps
    }
}
