import Foundation
import SwiftUI

enum SystemNotificationBadge: CustomStringConvertible, Equatable {
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

class SystemNotificationItem: Equatable {
    var bundleId: String
    var badge: SystemNotificationBadge
    var icon: any View
    var color: NSColor

    init(bundleId: String, badge: SystemNotificationBadge, icon: any View, color: NSColor) {
        self.bundleId = bundleId
        self.badge = badge
        self.icon = icon
        self.color = color
    }
    
    static func == (lhs: SystemNotificationItem, rhs: SystemNotificationItem) -> Bool {
        return lhs.bundleId == rhs.bundleId
    }

    func instance() -> SystemNotificationInstance {
        return SystemNotificationInstance(category: "system_notification", ty: .temporary(6), icon: { (notchViewModel: NotchViewModel) in self.icon }, action: { (notchViewModel: NotchViewModel) in SystemNotificationModel.shared.open(bundleId: self.bundleId) })
    }
}

struct NumberSquare: View {
    @State var notchViewModel: NotchViewModel
    let number: Int
    @State var isHover: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(isHover ? .white : .black)
            Text("\(number)")
                .font(.system(size: notchViewModel.deviceNotchRect.height * 0.5, weight: .medium))
                .foregroundColor(isHover ? .black : .white)
            Circle()
                .fill(Color.red)
                .frame(width: notchViewModel.deviceNotchRect.height * 0.2, height: notchViewModel.deviceNotchRect.height * 0.2)
                .offset(x: notchViewModel.deviceNotchRect.height * 0.25 + 2, y: -notchViewModel.deviceNotchRect.height * 0.25 - 2)
        }
        .frame(width: notchViewModel.deviceNotchRect.height * 0.7, height: notchViewModel.deviceNotchRect.height * 0.7)
        .animation(.easeInOut(duration: 0.2), value: isHover)
        .onHover { hover in
            self.isHover = hover
        }
    }
}

class SystemNotificationInstance: NotificationInstance, Equatable {
    var id: UUID
    var category: String
    var ty: NotificationType
    var icon: (NotchViewModel) -> any View
    var action: (NotchViewModel) -> Void
    
    init(category: String, ty: NotificationType, icon: @escaping (NotchViewModel) -> any View, action: @escaping (NotchViewModel) -> Void) {
        self.id = UUID()
        self.category = category
        self.ty = ty
        self.icon = icon
        self.action = action
    }
    
    static func == (lhs: SystemNotificationInstance, rhs: SystemNotificationInstance) -> Bool {
        return lhs.id == rhs.id
    }
}

class SystemNotificationModel: ObservableObject {
    static let shared = SystemNotificationModel()
    @ObservedObject var notchModel = NotchModel.shared
    @ObservedObject var notifModel = NotificationModel.shared
    @ObservedObject var apps = Apps.shared
    let monitor = BadgeMonitor.shared

    var total: Int32 = 0
    private let lock = NSLock()
    @Published var items: [String: SystemNotificationItem] = [:]

    init() {
        let monitoredAppIds = UserDefaults.standard.stringArray(forKey: "monitoredAppIds") ?? []
        for bundleId in monitoredAppIds {
            self.observe(bundleId: bundleId)
        }
    }

    func observe(bundleId: String) {
        if self.items.keys.contains(bundleId) {
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
            icon = NSImage(systemSymbolName: "app.badge", accessibilityDescription: nil) ?? NSImage()
        }
        self.items[bundleId] = SystemNotificationItem(bundleId: bundleId, badge: SystemNotificationBadge.null, icon: Image(nsImage: icon).resizable().aspectRatio(contentMode: .fit), color: NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        monitor.observe(
            bundleId: bundleId,
            onUpdate: { text in
                self.updateBadge(bundleId: bundleId, text: text)
            })
    }


    private func updateBadge(bundleId: String, text: String?) {
        lock.withLock {
            let badge = SystemNotificationBadge.fromString(str: text)
            guard let item = self.items[bundleId] else { return }

            if item.badge == badge {
                return
            }
            let old = item.badge.toInt32()
            self.total -= old

            let new = badge.toInt32()
            self.total += new
            item.badge = badge

            if new > old {
                self.notifModel.add(item: item.instance())
            } else if new == 0 {
                self.notifModel.remove(ty: .temporary(6), category: "system_notification")
            }
            if self.total != 0 {
                self.notifModel.add(item: SystemNotificationInstance(
                    category: "system_notification",
                    ty: .always,
                    icon: { (notchViewModel: NotchViewModel) in
                        AnyView(NumberSquare(notchViewModel: notchViewModel, number: Int(self.total))
                        ).aspectRatio(contentMode: .fit)
                    },
                    action: { (notchViewModel: NotchViewModel) in
                        notchViewModel.notchOpen(contentType: .notification)
                    }
                ))
            } else {
                self.notifModel.remove(ty: .always, category: "system_notification")
            }
        }
    }

    func open(bundleId: String) {
        for app in self.apps.coll {
            if app.bundleId == bundleId {
                if let window = app.windows.coll.first {
                    window.focus()
                    return
                }
            }
        }
        self.monitor.open(bundleId: bundleId)
    }

    func unobserve(bundleId: String) {
        if let item = self.items.removeValue(forKey: bundleId),
            let monitoredAppIds = UserDefaults.standard.stringArray(forKey: "monitoredAppIds")
        {
            let bundleId = item.bundleId
            let newAppIds = monitoredAppIds.filter { $0 != bundleId }
            UserDefaults.standard.set(newAppIds, forKey: "monitoredAppIds")
        }
    }
}
