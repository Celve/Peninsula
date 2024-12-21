//
//  NotchModel.swift
//  Peninsula
//
//  Created by Celve on 12/10/24.
//

import Foundation
import SwiftUICore
import Combine

class NotchModel: NSObject, ObservableObject {
    static let shared = NotchModel()
    let notchViewModels = NotchViewModels.shared
    @Published var isFirstOpen: Bool = true // for first open the app
    @Published var isFirstTouch: Bool = true // for first touch in the switch window
    @Published var switches: [Displayable] = []
    
    var cancellables: Set<AnyCancellable> = []
    @Published var windowsCounter: Int = 1
    var externalWindowsCounter: Int? = nil
    
    override init() {
        super.init()
        setupCancellables()
    }
    
    var globalWindowsPointer: Int {
        if switches.count == 0 {
            0
        } else {
            (windowsCounter % switches.count + switches.count) % switches.count
        }
    }
    
    var globalWindowsBegin: Int {
        (globalWindowsPointer / SwitchContentView.COUNT) * SwitchContentView.COUNT
    }
    
    var globalWindowsEnd: Int {
        min(globalWindowsBegin + SwitchContentView.COUNT, switches.count)
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
