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
            viewModel.notchOpen(contentType: .switching)
        }
    }
    
    func notchClose() {
        for viewModel in notchViewModels.inner {
            viewModel.notchClose()
        }
    }
    
    func closeAndFocus() {
        notchClose()
        if globalWindowsPointer < state.expand().count {
            state.expand()[globalWindowsPointer].focus()
        }
        initPointer(pointer: 0)
    }
    
    func setupEachCancellable(toggleType: HotKeyState, triggeredState: SwitchState) {
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
                    self.state = triggeredState
                    initPointer(pointer: 1)
                    if fasterSwitch {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                            if self?.state == triggeredState {
                                self?.notchOpen()
                            }
                        }
                    } else {
                        notchOpen()
                    }
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
                    self.state = .none
                case .hide:
                    print("hide")
                case .minimize:
                    print("mini")
                case .close:
                    print("close")
                    if globalWindowsPointer < state.expand().count {
                        state.expand()[globalWindowsPointer].close()
                    }
                case .quit:
                    print("quit")
                case .drop:
                    notchClose()
                    initPointer(pointer: 1)
                    self.state = .none
                }
            }
            .store(in: &cancellables)
    }
    
    func setupCancellables() {
        setupEachCancellable(toggleType: .cmdTab, triggeredState: .interWindows)
        setupEachCancellable(toggleType: .optTab, triggeredState: .interApps)
        setupEachCancellable(toggleType: .cmdBtick, triggeredState: .intraApp)
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
