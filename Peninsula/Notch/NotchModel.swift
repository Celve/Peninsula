//
//  NotchModel.swift
//  Peninsula
//
//  Created by Celve on 12/10/24.
//

import Foundation
import SwiftUICore
import Combine
import AppKit

enum SwitchState {
    case none
    case interWindows
    case interApps
    case intraApp
}

enum NotchContentType: Int, Codable, Hashable, Equatable {
    case apps
    case timer
    case notification
    case tray
    case traySettings
    case settings
    case switching
    
    func count() -> Int {
        return 7
    }
    
    func toTitle() -> String { // when modify this, don't forgfet to modify the count of cases
        switch self {
        case .apps:
            return "Apps"
        case .timer:
            return "Timer"
        case .tray:
            return "Tray"
        case .traySettings:
            return "TraySettings"
        case .notification:
            return "Notification"
        case .settings:
            return "Settings"
        case .switching:
            return "Switch"
        }
    }
    
    func next(invisibles: Dictionary<Self, Self>) -> Self {
        var contentType = self
        if let nextContentType = invisibles[contentType]{
            return nextContentType
        } else {
            repeat {
                if let nextValue = NotchContentType(rawValue: contentType.rawValue + 1) {
                    contentType = nextValue
                } else {
                    contentType = NotchContentType(rawValue: 0)!
                }
            } while invisibles.keys.contains(where: { $0 == contentType })
        }
        return contentType
    }

    func previous(invisibles: Dictionary<Self, Self>) -> Self {
        var contentType = self
        if let previousContentType = invisibles[contentType]{
            return previousContentType
        } else {
            repeat {
                if let previousValue = NotchContentType(rawValue: contentType.rawValue - 1) {
                    contentType = previousValue
                } else {
                    contentType = NotchContentType(rawValue: count() - 1)!
                }
            } while invisibles.keys.contains(where: { $0 == contentType })
        }
        return contentType
    }
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
    
    var stateExpansion: [any Switchable] {
        switch self.state {
        case .interWindows:
            return Windows.shared.coll
        case .interApps:
            return Apps.shared.useableInner
        case .intraApp:
            if Windows.shared.coll.count > 0 {
                let window = Windows.shared.coll[0]
                let application = window.application
                return application.windows.coll
            } else {
                return []
            }
        case .none:
            return []
        }
    }
    
    @PublishedPersist(key: "fasterSwitch", defaultValue: false)
    var fasterSwitch: Bool
    
    @PublishedPersist(key: "smallerNotch", defaultValue: false)
    var smallerNotch: Bool

    override init() {
        super.init()
        setupCancellables()
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
