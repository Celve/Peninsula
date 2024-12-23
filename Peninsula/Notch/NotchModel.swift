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
            return Applications.shared.inner
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

class NotchModel: NSObject, ObservableObject {
    static let shared = NotchModel()
    let notchViewModels = NotchViewModels.shared
    @Published var isFirstOpen: Bool = true // for first open the app
    @Published var isFirstTouch: Bool = true // for first touch in the switch window
    @Published var state: SwitchState = .none
    
    
    var cancellables: Set<AnyCancellable> = []
    @Published var windowsCounter: Int = 1
    var externalWindowsCounter: Int? = nil
    
    override init() {
        super.init()
        setupCancellables()
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
