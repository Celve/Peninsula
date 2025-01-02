//
//  NotchModel.swift
//  Peninsula
//
//  Created by Celve on 12/10/24.
//

import Foundation
import SwiftUICore
import Combine

enum SwitchState {
    case none
    case interWindows
    case interApps
    case intraApp
    
    func expand() -> [Switchable] {
        switch self {
        case .interWindows:
            return Windows.shared.inner
        case .interApps:
            return Applications.shared.useableInner 
        case .intraApp:
            if Windows.shared.inner.count > 0 {
                let window = Windows.shared.inner[0]
                let application = window.application
                return application.windows
            } else {
                return []
            }
        case .none:
            return []
        }
    }
}

enum NotchContentType: Int, Codable, Hashable, Equatable {
    case apps
    case notification
    case tray
    case traySettings
    case settings
    case switching
    
    func toTitle() -> String {
        switch self {
        case .apps:
            return "Apps"
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
}

class NotchModel: NSObject, ObservableObject {
    static let shared = NotchModel()
    let notchViewModels = NotchViewModels.shared
    @Published var isFirstOpen: Bool = true // for first open the app
    @Published var isFirstTouch: Bool = true // for first touch in the switch window
    @Published var state: SwitchState = .none
    var cancellables: Set<AnyCancellable> = []
    @Published var windowsCounter: Int = 1
    var externalWindowsCounter: Int? = nil
    @Published var invisibleContentTypes: Dictionary<NotchContentType, NotchContentType> = Dictionary()
    
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
        let count = state.expand().count
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
        min(globalWindowsBegin + SwitchContentView.COUNT, state.expand().count)
    }
    
    func updateExternalPointer(pointer: Int?) {
        externalWindowsCounter = pointer
        if let pointer = pointer, !isFirstTouch {
            windowsCounter = pointer
        }
    }
    
    func touch() {
        isFirstTouch = false
        if let counter = externalWindowsCounter {
            windowsCounter = counter
        }
    }
    
    func incrementPointer() {
        if globalWindowsPointer != 0 && globalWindowsPointer % SwitchContentView.COUNT == SwitchContentView.COUNT - 1 {
            externalWindowsCounter = nil
        }
        isFirstTouch = true
        windowsCounter += 1
    }
    
    func decrementPointer() {
        if globalWindowsPointer != 0 && globalWindowsPointer % SwitchContentView.COUNT == 0 {
            externalWindowsCounter = nil
        }
        isFirstTouch = true
        windowsCounter -= 1
    }
    
    func initPointer(pointer: Int) {
        isFirstTouch = true
        externalWindowsCounter = nil
        windowsCounter = pointer
    }
}
