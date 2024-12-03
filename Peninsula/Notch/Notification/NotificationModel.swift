import Cocoa
import Foundation
import Atomics
import SwiftUI

enum NotificationInfo: CustomStringConvertible, Equatable {
    case count(Int32)
    case text(String)
    case null

    var description: String {
        switch self {
        case .count(let count):
            String(count)
        case .text(let text):
            String(text)
        case .null:
            String(0)
        }
    }

    static func fromString(str: String?) -> Self {
        if let str = str {
            if let value = Int32(str) {
                return Self.count(value)
            } else {
                return Self.text(str)
            }
        } else {
            return Self.null
        }
    }

    func toInt32() -> Int32 {
        switch self {
        case .count(let count):
            return count
        case .text(_):
            return 1
        case .null:
            return 0
        }
    }
}

enum NotificationBadge: Equatable {
    case num(Int32)
    case icon(NSImage)
    case time(Int32, Int32)
    case none
}

class NotificationItem: Equatable {
    var name: String
    var bundleId: String
    var badge: NotificationInfo
    var icon: NSImage

    init(name: String, bundleId: String, badge: NotificationInfo, icon: NSImage) {
        self.name = name
        self.bundleId = bundleId
        self.badge = badge
        self.icon = icon
    }

    static func == (lhs: NotificationItem, rhs: NotificationItem) -> Bool {
        return lhs.name == rhs.name && lhs.bundleId == rhs.bundleId
    }
}

class NotificationModel: ObservableObject {
    static let shared = NotificationModel()
    @ObservedObject var apps = Applications.shared

    var total: Int32 = 0
    var version: UInt64 = 1
    var displayedVersion: UInt64 = 0
    private let lock = NSLock()
    var occupied = false
    @Published var items: [String: NotificationItem] = [:]
    @Published var displayedBadge: NotificationBadge = .none
    @Published var displayedName: String = ""
    var displayedNum: Int32 = 0
    let monitor = BadgeMonitor.shared
    private var timer: Timer?

    init() {
        let monitoredAppIds = UserDefaults.standard.stringArray(forKey: "monitoredAppIds") ?? []
        for bundleId in monitoredAppIds {
            var appName = bundleId
            if let appFullPath = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: bundleId)?.absoluteURL.path,
                let targetBundle = Bundle(path: appFullPath),
                let name = targetBundle.object(forInfoDictionaryKey: kCFBundleNameKey as String)
                    as? String
            {
                appName = name
            }
            self.observe(name: appName, bundleId: bundleId)
        }
    }

    private func updateBadge(name: String, text: String?) {
        let badge = NotificationInfo.fromString(str: text)
        guard let item = self.items[name] else { return }

        if item.badge == badge {
            return
        }
        let old = item.badge.toInt32()
        self.total -= old

        let new = badge.toInt32()
        self.total += new
        item.badge = badge

        if new > old {
            lock.withLock {
                if !self.occupied {
                    self.displayedBadge = .icon(item.icon)
                    self.displayedNum = self.total
                    self.displayedName = name
                    
                    let version = self.version
                    self.displayedVersion = version
                    self.version += 1
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6.18) {
                        self.lock.withLock {
                            if self.displayedVersion == version {
                                self.displayTotal()
                            }
                        }
                    }
                }
            }

        } else {
            self.displayTotal()
        }
    }

    private func displayTotal() {
        self.displayedName = ""
        if self.total == 0 {
            self.displayedBadge = .none
            self.displayedNum = 0
        } else {
            self.displayedBadge = .num(self.total)
            self.displayedNum = self.total
        }
    }
    
    func open(name: String) {
        for app in self.apps.inner {
            if app.name == name {
                if let window = app.focusedWindow {
                    window.focus()
                    return
                } else if let window = app.windows.first {
                    window.focus()
                    return
                }
            }
        }
        self.monitor.open(appName: name)
    }

    func observe(name: String, bundleId: String) {
        if self.items.keys.contains(name) {
            return
        }

        var monitoredAppIds = UserDefaults.standard.stringArray(forKey: "monitoredAppIds") ?? []
        monitoredAppIds.append(bundleId)
        UserDefaults.standard.set(monitoredAppIds, forKey: "monitoredAppIds")

        let appFullPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)?
            .absoluteURL.path
        let icon: NSImage
        if let appFullPath = appFullPath {
            let desiredSize = NSSize(width: 128, height: 128)
            let desiredRect = NSRect(origin: .zero, size: desiredSize)
            let smallIcon = NSWorkspace.shared.icon(forFile: appFullPath)
            if let bestRep = smallIcon.bestRepresentation(
                for: desiredRect, context: nil, hints: nil)
            {
                let largeIcon = NSImage(size: desiredSize)
                largeIcon.addRepresentation(bestRep)
                icon = largeIcon
            } else {
                icon = smallIcon
            }
        } else {
            icon = NSImage(systemSymbolName: "app.badge", accessibilityDescription: nil)!
        }
        self.items[name] = NotificationItem(
            name: name, bundleId: bundleId, badge: NotificationInfo.null, icon: icon)
        monitor.observe(
            appName: name,
            onUpdate: { text in
                self.updateBadge(name: name, text: text)
            })
    }

    func unobserve(name: String) {
        if let item = self.items.removeValue(forKey: name),
            let monitoredAppIds = UserDefaults.standard.stringArray(forKey: "monitoredAppIds")
        {
            let bundleId = item.bundleId
            let newAppIds = monitoredAppIds.filter { $0 != bundleId }
            UserDefaults.standard.set(newAppIds, forKey: "monitoredAppIds")
        }
    }
}
