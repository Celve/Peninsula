import Cocoa
import Combine
import Foundation
import SwiftUI

enum NotificationType {
    case temporary(Int) // number of seconds to show
    case always 
}

protocol NotificationInstance {
    var id: UUID { get }
    var category: String { get }
    var ty: NotificationType { get }
    var icon: (NotchViewModel) -> any View { get }
    var action: (NotchViewModel) -> Void { get }
}

class NotificationModel: ObservableObject {
    static let shared = NotificationModel()
    @Published var alwaysItems: [String: NotificationInstance] = [:]
    @Published var temporaryItems: [String: NotificationInstance] = [:]
    @Published var namesSet: Set<String> = []
    @Published var names: [String] = []
    private let lock = NSLock()

    func add(item: NotificationInstance) {
        lock.withLock {
            switch item.ty {
                case .always:
                    alwaysItems[item.category] = item
                    if !namesSet.contains(item.category) {
                        names.append(item.category)
                        namesSet.insert(item.category)
                    }
                case .temporary(let time):
                temporaryItems[item.category] = item
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(time)) {
                    if self.temporaryItems[item.category]?.id == item.id {
                        self.temporaryItems.removeValue(forKey: item.category)
                        if self.alwaysItems[item.category] == nil {
                            if let index = self.names.firstIndex(of: item.category) {
                                self.names.remove(at: index)
                            }
                            self.namesSet.remove(item.category)
                        }
                    }
                }
            }
        }
    }

    func remove(ty: NotificationType, category: String) {
        lock.withLock {
            switch ty {
            case .always:
                alwaysItems.removeValue(forKey: category)
                if temporaryItems[category] == nil {
                    if let index = names.firstIndex(of: category) {
                        names.remove(at: index)
                    }
                    namesSet.remove(category)
                }
            case .temporary:
                temporaryItems.removeValue(forKey: category)
                if alwaysItems[category] == nil {
                    if let index = names.firstIndex(of: category) {
                        names.remove(at: index)
                    }
                    namesSet.remove(category)
                }
            }
        }
    }
}
