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
    
    @ObservedObject var windows = Windows.shared
    
    var cancellables: Set<AnyCancellable> = []
    @Published var windowsCounter: Int = 1
    
    override init() {
        super.init()
        setupCancellables()
    }
    
    var globalWindowsPointer: Int {
        if windows.inner.count == 0 {
            0
        } else {
            (windowsCounter % windows.inner.count + windows.inner.count) % windows.inner.count
        }
    }
    
    var globalWindowsBegin: Int {
        (globalWindowsPointer / SwitchContentView.COUNT) * SwitchContentView.COUNT
    }
    
    var globalWindowsEnd: Int {
        min(globalWindowsBegin + SwitchContentView.COUNT, windows.inner.count)
    }
    
    func updatePointer(pointer: Int) {
        if isFirstTouch {
            isFirstTouch = false
        } else {
            windowsCounter = pointer
        }
    }
    
    func incrementPointer() {
        if globalWindowsPointer != 0 && globalWindowsPointer % SwitchContentView.COUNT == SwitchContentView.COUNT - 1 {
            isFirstTouch = true
        }
        windowsCounter += 1
    }
    
    func decrementPointer() {
        if globalWindowsPointer != 0 && globalWindowsPointer % SwitchContentView.COUNT == 0 {
            isFirstTouch = true
        }
        windowsCounter -= 1
    }
    
    func initPointer(pointer: Int) {
        isFirstTouch = true
        windowsCounter = pointer
    }
}