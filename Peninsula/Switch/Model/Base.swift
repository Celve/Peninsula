//
//  Base.swift
//  Peninsula
//
//  Created by Celve on 1/7/25.
//


import AppKit
import Foundation

protocol Collection: AnyObject, Equatable {
    associatedtype M: Element where M.C == Self
    var id: UUID { get set }
    var coll: [M] { get set }
}

extension Collection {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }

    func fetch(axElement: AXUIElement) -> M? {
        return coll.first(where: { $0.axElement == axElement })
    }

    @MainActor
    func peek(element: M) {
        if let order = element.getOrder(collId: self.id) {
            element.setOrder(collId: self.id, order: self.coll.count - 1)
            for i in 0..<coll.count {
                let other = coll[i]
                if let otherOrder = other.getOrder(collId: self.id), otherOrder > order {
                    other.setOrder(collId: self.id, order: otherOrder - 1)
                }
            }
            sort()
        }
    }

    @MainActor
    func add(element: M) {
        if let other = coll.first(where: { $0 == element }) {
            peek(element: other)
        } else if let _ = element.getOrder(collId: self.id) {
            peek(element: element)
        } else {
            element.colls.append((self, coll.count))
            coll.append(element)
            sort()
        }
    }

    @MainActor
    func remove(element: M) {
        if let order = element.getOrder(collId: self.id) {
            coll.removeAll(where: { $0 == element })
            element.remove(collId: self.id)
            sort()
        }
    }

    func sort() {
        let collId = self.id
        coll.sort {
            return $0.getOrder(collId: collId) ?? 0 > $1.getOrder(collId: collId) ?? 0
        }
    }
}

protocol Element: AnyObject, Equatable {
    associatedtype M: Element where M.C == C
    associatedtype C: Collection where C.M == M
    var axElement: AXUIElement { get set }
    var colls: [(C, Int)] { get set }
    var covs: [any Element] { get set }
}
    

extension Element {
    @MainActor
    func add(coll: C) {
        guard let other = self as? M else { return }
        coll.add(element: other)
    }

    @MainActor
    func peek() {
        guard let other = self as? M else { return }
        for i in 0..<colls.count {
            let (coll, _) = colls[i]
            coll.peek(element: other)
        }
        for cov in covs {
            cov.peek()
        }
    }

    func getOrder(collId: UUID) -> Int? {
        for (coll, order) in colls {
            if collId == coll.id {
                return order
            }
        }
        return nil
    }

    func setOrder(collId: UUID, order: Int) {
        for i in 0..<colls.count {
            let (coll, _) = colls[i]
            if collId == coll.id {
                colls[i].1 = order
                break
            }
        }
    }

    func remove(collId: UUID) {
        for i in 0..<colls.count {
            let (coll, _) = colls[i]
            if collId == coll.id {
                colls.remove(at: i)
                break
            }
        }

    }

    @MainActor
    func destroy() {
        guard let other = self as? M else { return }
        while let (coll, _) = colls.last {
            coll.remove(element: other)
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.axElement == rhs.axElement
    }

    func getIcon() -> NSImage? {
        return nil
    }

    func getTitle() -> String? {
        return nil
    }

    func focus() {}

    func close() {}
}
