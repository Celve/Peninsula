import Cocoa
import Combine
import Foundation
import SwiftUI

enum BadgeType {
    case transient(Int)
    case always
}

protocol BadgeItem {
    var id: UUID { get }
    var category: String { get }
    var size: CGSize { get }
    var ty: BadgeType { get }
    var view: (NotchViewModel) -> any View { get }
    var action: (NotchViewModel) -> Void { get }
}

class BadgeModel: ObservableObject {
    static let shared = BadgeModel()
    @Published var alwaysItems: [BadgeItem] = []
    @Published var temporaryItems: [BadgeItem] = []
    private let lock = NSLock()

    func add(item: BadgeItem) {
        lock.withLock {
            switch item.ty {
                case .always:
                    alwaysItems.append(item)
                case .transient(let time):
                    temporaryItems.append(item)
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(time)) {
                        self.temporaryItems.removeAll { $0.id == item.id }
                    }
            }
        }
    }

    func remove(ty: BadgeType, item: BadgeItem) {
        lock.withLock {
            switch ty {
            case .always:
                alwaysItems.removeAll { $0.id == item.id }
            case .transient:
                temporaryItems.removeAll { $0.id == item.id }
            }
        }
    }
}
