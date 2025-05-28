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
    func getMatchableString() -> MatchableString
    func focus()
    func hide()
    func minimize()
    func quit()
    func close()
}
