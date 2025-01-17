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
        if let index = coll.firstIndex(where: { $0 == element }) {
            coll.remove(at: index)
            coll.insert(element, at: 0)
        }
    }

    @MainActor
    func add(element: M) {
        if let other = coll.first(where: { $0 == element }) {
            peek(element: other)
        } else {
            element.colls.append(self)
            coll.insert(element, at: 0)
        }
    }

    @MainActor
    func remove(element: M) {
        coll.removeAll(where: { $0 == element })
        element.remove(collId: self.id)
    }
}

protocol Element: AnyObject, Equatable {
    associatedtype M: Element where M.C == C
    associatedtype C: Collection where C.M == M
    var axElement: AXUIElement { get set }
    var colls: [C] { get set }
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
            let coll = colls[i]
            coll.peek(element: other)
        }
        for cov in covs {
            cov.peek()
        }
    }

    func remove(collId: UUID) {
        for i in 0..<colls.count {
            let coll = colls[i]
            if collId == coll.id {
                colls.remove(at: i)
                break
            }
        }

    }

    @MainActor
    func destroy() {
        guard let other = self as? M else { return }
        while let coll = colls.last {
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
