//
//  NotchModel+Events.swift
//  Peninsula
//
//  Created by Celve on 12/10/24.
//

import Cocoa
import Combine
import Foundation
import SwiftUI


extension NotchModel {
    func closeAndFocus() {
        for viewModel in notchViewModels.inner {
            viewModel.notchClose()
        }
        if globalWindowsPointer < windows.inner.count {
            windows.inner[globalWindowsPointer].focus()
        }
        initPointer(pointer: 0)
    }
    
    func setupCancellables() {
        let hotKeyObserver = HotKeyObserver.shared
        let hotKeyToggle = hotKeyObserver.cmdTabToggle.toggle
        hotKeyToggle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] input in
                guard let self else { return }
                switch input {
                case .on:
                    initPointer(pointer: 1)
                    for viewModel in notchViewModels.inner {
                        viewModel.notchOpen(.switching)
                    }
                case .forward:
                    incrementPointer()
                    for viewModel in notchViewModels.inner {
                        viewModel.notchOpen(.switching)
                    }
                case .backward:
                    decrementPointer()
                    for viewModel in notchViewModels.inner {
                        viewModel.notchOpen(.switching)
                    }
                case .off:
                    if self.isFirstOpen {
                        self.isFirstOpen = false
                    } else {
                        closeAndFocus()
                    }
                case .drop:
                    for viewModel in notchViewModels.inner {
                        viewModel.notchClose()
                    }
                    initPointer(pointer: 1)
                }
            }
            .store(in: &cancellables)
        
        let events = EventMonitors.shared
        events.mouseLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mouseLocation in
                guard let self else { return }
                self.touch()
            }
            .store(in: &cancellables)
    }
}
