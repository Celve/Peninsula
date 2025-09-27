//
//  NotchModel.swift
//  Peninsula
//
//  Created by Celve on 12/10/24.
//

import Sparkle
import Foundation
import Combine
import AppKit
import SwiftUI

enum SwitchState: String, CaseIterable, Codable, Identifiable {
    var id: String { rawValue }
    
    case none
    case interWindows
    case interApps
    case intraApp
}

class NotchModel: NSObject, ObservableObject {
    static let shared = NotchModel()
    let notchViewModels = NotchViewModels.shared
    @Published var isFirstOpen: Bool = true // for first open the app
    @Published var lastMouseLocation: NSPoint = NSEvent.mouseLocation // for first touch in the switch window
    @Published var state: SwitchState = .none
    var cancellables: Set<AnyCancellable> = []
    @Published var selectionCounter: Int = 1
    var externalSelectionCounter: Int? = nil
    @Published var invisibleContentTypes: Dictionary<NotchContentType, NotchContentType> = Dictionary()
    @Published var buffer: String = ""
    @Published var cursor: Int = 0
    @PublishedPersist(key: "cmdTabTrigger", defaultValue: .interWindows)
    var cmdTabTrigger: SwitchState
    @PublishedPersist(key: "optTabTrigger", defaultValue: .interApps)
    var optTabTrigger: SwitchState
    @PublishedPersist(key: "cmdBtickTrigger", defaultValue: .intraApp)
    var cmdBtickTrigger: SwitchState
    @PublishedPersist(key: "optBtickTrigger", defaultValue: .none)
    var optBtickTrigger: SwitchState
    @Published var filterString: String = ""
    @Published var isKeyboardTriggered: Bool = false
    @Published var contentType: NotchContentType = .switching
    
    var updaterController: SPUStandardUpdaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    
    var switchItems: [(any Switchable, NSImage, [MatchableString.MatchResult])] {
        SwitchManager.shared.items(
            state: state,
            contentType: contentType,
            filterString: filterString
        )
    }
    
    @PublishedPersist(key: "fasterSwitch", defaultValue: false)
    var fasterSwitch: Bool
    
    @PublishedPersist(key: "smallerNotch", defaultValue: false)
    var smallerNotch: Bool

    override init() {
        super.init()
        setupCancellables()
        setupKeyboardShortcuts()
        setupInvisibleViews()
    }
    
    func setupInvisibleViews() {
        invisibleContentTypes[.traySettings] = .tray
        invisibleContentTypes[.switching] = .tray
    }
    
    var activeIndex: Int {
        let count = SwitchManager.shared.itemsCount(
            state: state,
            contentType: contentType,
            filterString: filterString
        )
        if count == 0 {
            return 0
        } else {
            return (selectionCounter % count + count) % count
        }
    }
    
    var pageStart: Int {
        (activeIndex / SwitchContentView.COUNT) * SwitchContentView.COUNT
    }
    
    var pageEnd: Int {
        let count = SwitchManager.shared.itemsCount(
            state: state,
            contentType: contentType,
            filterString: filterString
        )
        return min(pageStart + SwitchContentView.COUNT, count)
    }
    
    func updateExternalPointer(pointer: Int?) {
        externalSelectionCounter = pointer
        let mouseLocation = NSEvent.mouseLocation
        if let pointer = pointer, lastMouseLocation != mouseLocation {
            selectionCounter = pointer
        }
        lastMouseLocation = mouseLocation
    }
    
    func incrementPointer() {
        if activeIndex != 0 && activeIndex % SwitchContentView.COUNT == SwitchContentView.COUNT - 1 {
            externalSelectionCounter = nil
        }
        selectionCounter += 1
    }
    
    func decrementPointer() {
        if activeIndex != 0 && activeIndex % SwitchContentView.COUNT == 0 {
            externalSelectionCounter = nil
        }
        selectionCounter -= 1
    }
    
    func initPointer(pointer: Int) {
        lastMouseLocation = NSEvent.mouseLocation
        externalSelectionCounter = nil
        selectionCounter = pointer
    }
}
