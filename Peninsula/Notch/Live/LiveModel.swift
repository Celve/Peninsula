import Cocoa
import Combine
import Foundation
import SwiftUI

enum LiveType {
    case transient(Int)
    case always 
}

protocol LiveItem {
    var id: UUID { get }
    var category: String { get }
    var ty: LiveType { get }
    var icon: (NotchViewModel) -> any View { get }
    var action: (NotchViewModel) -> Void { get }
}

class LiveModel: ObservableObject {
    static let shared = LiveModel()
    @Published var alwaysItems: [String: LiveItem] = [:]
    @Published var temporaryItems: [String: LiveItem] = [:]
    @Published var names: [String] = []
    private let lock = NSLock()

    func add(item: LiveItem) {
        lock.withLock {
            switch item.ty {
                case .always:
                    alwaysItems[item.category] = item
                    if !names.contains(item.category) {
                        names.append(item.category)
                    }
                case .transient(let time):
                temporaryItems[item.category] = item
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(time)) {
                    if self.temporaryItems[item.category]?.id == item.id {
                        self.temporaryItems.removeValue(forKey: item.category)
                        if self.alwaysItems[item.category] == nil {
                            if let index = self.names.firstIndex(of: item.category) {
                                self.names.remove(at: index)
                            }
                        }
                    }
                }
            }
        }
    }

    func remove(ty: LiveType, category: String) {
        lock.withLock {
            switch ty {
            case .always:
                alwaysItems.removeValue(forKey: category)
                if temporaryItems[category] == nil {
                    if let index = names.firstIndex(of: category) {
                        names.remove(at: index)
                    }
                }
            case .transient:
                temporaryItems.removeValue(forKey: category)
                if alwaysItems[category] == nil {
                    if let index = names.firstIndex(of: category) {
                        names.remove(at: index)
                    }
                }
            }
        }
    }
}
