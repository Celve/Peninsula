//
//  NotchModel.swift
//  Peninsula
//
//  Created by Celve on 12/10/24.
//

import Sparkle
import Foundation
import SwiftUICore
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
    @Published var windowsCounter: Int = 1
    var externalWindowsCounter: Int? = nil
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
    
    private var cachedStateExpansion: [(any Switchable, NSImage, [MatchableString.MatchResult])] = []
    private var lastState: SwitchState = .none
    private var lastContentType: NotchContentType = .apps
    private var lastFilterString: String = ""
    
    var stateExpansion: [(any Switchable, NSImage, [MatchableString.MatchResult])] {
        // Check if we need to recalculate
        if state != lastState || contentType != lastContentType || 
           (contentType == .searching && filterString != lastFilterString) {
            lastState = state
            lastContentType = contentType
            lastFilterString = filterString
            
            let rawExpansion: [any Switchable] = switch self.state {
            case .interWindows:
                Windows.shared.coll
            case .interApps:
                Apps.shared.useableInner
            case .intraApp:
                if Windows.shared.coll.count > 0 {
                    Windows.shared.coll[0].application.windows.coll
                } else {
                    []
                }
            case .none:
                []
            }
            
            if contentType == .searching {
                let filterString = filterString.lowercased()
                cachedStateExpansion = rawExpansion.compactMap { (item) -> (any Switchable, NSImage, [MatchableString.MatchResult])? in
                    if let matchableString = item.getMatchableString().matches(string: filterString) {
                        return (item, item.getIcon() ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)!, matchableString)
                    }
                    return nil
                }
            } else {
                cachedStateExpansion = rawExpansion.compactMap { (item) -> (any Switchable, NSImage, [MatchableString.MatchResult])? in
                    return (item, item.getIcon() ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)!, [.unmatched(item.getTitle() ?? "")])
                }
            }
        }
        return cachedStateExpansion
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
    
    var globalWindowsPointer: Int {
        let count = stateExpansion.count
        if count == 0 {
            return 0
        } else {
            return (windowsCounter % count + count) % count
        }
    }
    
    var globalWindowsBegin: Int {
        (globalWindowsPointer / SwitchContentView.COUNT) * SwitchContentView.COUNT
    }
    
    var globalWindowsEnd: Int {
        min(globalWindowsBegin + SwitchContentView.COUNT, stateExpansion.count)
    }
    
    func updateExternalPointer(pointer: Int?) {
        externalWindowsCounter = pointer
        let mouseLocation = NSEvent.mouseLocation
        if let pointer = pointer, lastMouseLocation != mouseLocation {
            windowsCounter = pointer
        }
        lastMouseLocation = mouseLocation
    }
    
    func incrementPointer() {
        if globalWindowsPointer != 0 && globalWindowsPointer % SwitchContentView.COUNT == SwitchContentView.COUNT - 1 {
            externalWindowsCounter = nil
        }
        windowsCounter += 1
    }
    
    func decrementPointer() {
        if globalWindowsPointer != 0 && globalWindowsPointer % SwitchContentView.COUNT == 0 {
            externalWindowsCounter = nil
        }
        windowsCounter -= 1
    }
    
    func initPointer(pointer: Int) {
        lastMouseLocation = NSEvent.mouseLocation
        externalWindowsCounter = nil
        windowsCounter = pointer
    }
}
