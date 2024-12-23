//
//  Displayable.swift
//  Peninsula
//
//  Created by Linyu Wu on 12/20/24.
//

import AppKit

protocol Switchable {
    func getIcon() -> NSImage?
    func getTitle() -> String?
    func focus()
    func close()
}

protocol Switches {
    func getSwitches() -> [Switchable]
}

class EmptySwitches: Switches {
    func getSwitches() -> [Switchable] {
        return []
    }
}
