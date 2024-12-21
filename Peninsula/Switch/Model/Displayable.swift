//
//  Displayable.swift
//  Peninsula
//
//  Created by Linyu Wu on 12/20/24.
//

import AppKit

protocol Displayable {
    func getIcon() -> NSImage?
    func getTitle() -> String?
    func focus()
}

