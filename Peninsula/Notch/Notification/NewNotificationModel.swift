import Cocoa
import Combine
import Foundation
import SwiftUI

enum NewNotificationType {
    case temporary(Int) // number of seconds to show
    case always 
}

protocol NewNotificationInstance {
    var id: UUID { get }
    var category: String { get }
    var ty: NewNotificationType { get }
    var icon: any View { get }
    var action: (NotchViewModel) -> Void { get }
}

class NewNotificationModel: ObservableObject {
    static let shared = NewNotificationModel()
    @Published var alwaysItems: [String: NewNotificationInstance] = [:]
    @Published var temporaryItems: [String: NewNotificationInstance] = [:]
    @Published var names: Set<String> = []
    private let lock = NSLock()

    func add(item: NewNotificationInstance) {
        print("add", item.ty, item.category)
        lock.withLock {
            switch item.ty {
                case .always:
                    alwaysItems[item.category] = item
                names.insert(item.category)
            case .temporary(let time):
                temporaryItems[item.category] = item
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(time)) {
                    if self.temporaryItems[item.category]?.id == item.id {
                        self.temporaryItems.removeValue(forKey: item.category)
                        if self.alwaysItems[item.category] == nil {
                            self.names.remove(item.category)
                        }
                    }
                }
            }
        }
    }

    func remove(ty: NewNotificationType, category: String) {
        print("remove", ty, category)
        lock.withLock {
            switch ty {
            case .always:
                alwaysItems.removeValue(forKey: category)
                if temporaryItems[category] == nil {
                    names.remove(category)
                }
            case .temporary:
                temporaryItems.removeValue(forKey: category)
                if alwaysItems[category] == nil {
                    names.remove(category)
                }
            }
        }
    }
}
