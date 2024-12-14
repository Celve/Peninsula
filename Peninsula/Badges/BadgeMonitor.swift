//
//  BadgeMonitor.swift
//  Island
//
//  Created by Celve on 9/20/24.
//

import AppKit
import Foundation

class BadgeMonitor {
    static let shared = BadgeMonitor(checkInterval: 0.3)

    var timer: Timer?
    var checkInterval: Double
    var appCreateObserver: AXObserver? = nil
    var appDestroyObserver: AXObserver? = nil
    var observedApps: [String: ObservedApp]

    init(checkInterval: Double) {
        self.observedApps = [:]
        self.checkInterval = checkInterval
        let routine: (Timer) -> Void = { timer in
            if self.appCreateObserver == nil || self.appDestroyObserver == nil {
                self.setupAxObserversOnDock()
            }

            self.observedApps.values.forEach { app in
                app.updateBadge()
            }
        }
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true, block: routine)
        timer?.fire()
    }

    func observe(bundleId: String, onUpdate: @escaping (String?) -> Void) {
        let app = ObservedApp(bundleId: bundleId, onBadgeUpdate: onUpdate)
        observedApps[bundleId] = app
        app.tryUpdateElement()
    }
    
    public func open(bundleId: String) {
        if let cachedTargetAppElement = observedApps[bundleId]?.appElement {
            AXUIElementPerformAction(cachedTargetAppElement, kAXPressAction as CFString)
        }
    }

    private func setupAxObserversOnDock() {
        guard
            let dockProcessId = NSRunningApplication.runningApplications(
                withBundleIdentifier: "com.apple.dock"
            ).last?.processIdentifier
        else {
            return
        }

        AXObserverCreateWithInfoCallback(
            dockProcessId,
            { (observer, element, notification, userData, refCon) in
                if let refCon = refCon {
                    let this = Unmanaged<BadgeMonitor>.fromOpaque(refCon)
                        .takeUnretainedValue()
                    this.reloadAppElements()
                }
            }, &appCreateObserver)

        AXObserverCreateWithInfoCallback(
            dockProcessId,
            { (observer, element, notification, userData, refCon) in
                if let refCon = refCon {
                    let this = Unmanaged<BadgeMonitor>.fromOpaque(refCon)
                        .takeUnretainedValue()
                    this.reloadAppElements()
                }
            }, &appDestroyObserver)

        if let observer = appCreateObserver {
            let callbackPTR = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

            if AXObserverAddNotification(
                observer, AXUIElementCreateApplication(dockProcessId),
                kAXCreatedNotification as CFString, callbackPTR) == .success
            {
                print("Successfully added element created Notification!")
            } else {
                appCreateObserver = nil
            }

            CFRunLoopAddSource(
                RunLoop.current.getCFRunLoop(), AXObserverGetRunLoopSource(observer),
                CFRunLoopMode.defaultMode)
        }

        if let observer = appDestroyObserver {
            let callbackPTR = UnsafeMutableRawPointer(Unmanaged.passUnretained(self) .toOpaque())

            if AXObserverAddNotification(
                observer, AXUIElementCreateApplication(dockProcessId),
                kAXUIElementDestroyedNotification as CFString, callbackPTR) == .success
            {
                print("Successfully added element destroyed Notification!")
            } else {
                appDestroyObserver = nil
            }

            CFRunLoopAddSource(
                RunLoop.current.getCFRunLoop(), AXObserverGetRunLoopSource(observer),
                CFRunLoopMode.defaultMode)
        }

        if appCreateObserver != nil && appDestroyObserver != nil {
            reloadAppElements()
        }
    }

    private func reloadAppElements() {
        observedApps.values.forEach { app in
            app.tryUpdateElement()
        }
    }
}

class ObservedApp {
    let bundleId: String
    var appElement: AXUIElement?
    let onBadgeUpdate: (String?) -> Void

    init(
        bundleId: String, appElement: AXUIElement? = nil, onBadgeUpdate: @escaping (String?) -> Void
    ) {
        self.bundleId = bundleId
        self.appElement = appElement
        self.onBadgeUpdate = onBadgeUpdate
        if self.appElement == nil {
            tryUpdateElement()
        }
    }

    func updateBadge() {
        guard let appElement = self.appElement else { return }
        
        var statusLabel: AnyObject?
        AXUIElementCopyAttributeValue(appElement, "AXStatusLabel" as CFString, &statusLabel)

        onBadgeUpdate(statusLabel as? String)
    }

    func tryUpdateElement() {
        // the AXTitle is equivalent to localizedName in NSRunningApp, so we have to retrieve from there
        
        var localizedName: String? = nil
        for app in Applications.shared.inner {
            if app.bundleId == self.bundleId {
                localizedName = app.name
            }
        }
        
        guard let appName = localizedName else { return }
        
        guard
            let dockProcessId = NSRunningApplication.runningApplications(
                withBundleIdentifier: "com.apple.dock"
            ).last?.processIdentifier
        else {
            return
        }

        let dock = AXUIElementCreateApplication(dockProcessId)
        guard let dockChildren = getSubElements(root: dock) else {
            return
        }

        // Get badge text by lookup dock elements
        for child in dockChildren {
            var title: AnyObject?

            AXUIElementCopyAttributeValue(child, kAXTitleAttribute as CFString, &title)
            if let titleStr = title as? String, titleStr == appName {
                self.appElement = child
            }
        }
    }

    private func getSubElements(root: AXUIElement) -> [AXUIElement]? {
        var childrenCount: CFIndex = 0
        var err = AXUIElementGetAttributeValueCount(root, "AXChildren" as CFString, &childrenCount)
        var result: [AXUIElement] = []

        if case .success = err {
            var subElements: CFArray?
            err = AXUIElementCopyAttributeValues(
                root, "AXChildren" as CFString, 0, childrenCount, &subElements)
            if case .success = err {
                if let children = subElements as? [AXUIElement] {
                    result.append(contentsOf: children)
                    children.forEach { element in
                        if let nestedChildren = getSubElements(root: element) {
                            result.append(contentsOf: nestedChildren)
                        }
                    }
                }

                return result
            }
        }

        print("Error \(err.rawValue)")
        return nil
    }
}
