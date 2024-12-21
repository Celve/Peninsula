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
    func notchOpen() {
        for viewModel in notchViewModels.inner {
            viewModel.notchOpen(.switching)
        }
    }
    
    func notchClose() {
        for viewModel in notchViewModels.inner {
            viewModel.notchClose()
        }
    }
    
    func closeAndFocus() {
        notchClose()
        if globalWindowsPointer < switches.count {
            switches[globalWindowsPointer].focus()
        }
        initPointer(pointer: 0)
    }
    
    enum SwitchType {
        case windows
        case apps
        case innerApp
    }
    
    func setupEachCancellable(toggleType: HotKeyState, triggeredType: SwitchType) {
        let hotKeyObserver = HotKeyObserver.shared
        let hotKeyToggle = switch toggleType {
        case .cmdBtick:
            hotKeyObserver.cmdBtickTogggle
        case .cmdTab:
            hotKeyObserver.cmdTabToggle
        case .optBtick:
            hotKeyObserver.optBtickTogggle
        case .optTab:
            hotKeyObserver.optTabToggle
        case .none:
            hotKeyObserver.optTabToggle // should not happen, just a placeholder
        }
            
        hotKeyToggle.toggle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] input in
                guard let self else { return }
                switch input {
                case .on:
                    switch triggeredType {
                    case .windows:
                        switches = Windows.shared.inner
                    case .apps:
                        switches = Applications.shared.inner
                    case .innerApp:
                        if Windows.shared.inner.count > 0 {
                            let window = Windows.shared.inner[0]
                            let application = window.application
                            switches = application.windows
                        }
                    }
                    initPointer(pointer: 1)
                    notchOpen()
                case .forward:
                    incrementPointer()
                case .backward:
                    decrementPointer()
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
        
    }
    
    func setupCancellables() {
        setupEachCancellable(toggleType: .cmdTab, triggeredType: .windows)
        setupEachCancellable(toggleType: .optTab, triggeredType: .apps)
        setupEachCancellable(toggleType: .cmdBtick, triggeredType: .innerApp)
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
