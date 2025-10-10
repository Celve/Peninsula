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
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleSearchInterWindows = Self("toggleSearchWindows")
    static let toggleSearchApps = Self("toggleSwitching")
    static let toggleSearchIntraWindows = Self("toggleSearchIntraWindows")
}

extension NotchModel {
    func notchOpen(galleryItem: GalleryItem) {
        filterString = ""
        isKeyboardTriggered = true
        self.contentType = contentType
        for viewModel in notchViewModels.inner {
            viewModel.notchOpen(galleryItem: galleryItem)
        }
    }

    func notchClose() {
        isKeyboardTriggered = false
        for viewModel in notchViewModels.inner {
            viewModel.notchClose()
        }
    }
    
    func closeAndFocus() {
        notchClose()
        if activeIndex < switchItems.count {
            switchItems[activeIndex].0.focus()
        }
        initPointer(pointer: 0)
    }
    
    func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyDown(for: .toggleSearchInterWindows) {
            if !self.isKeyboardTriggered {
                self.state = .interWindows
                self.initPointer(pointer: 1)
                self.notchOpen(galleryItem: .searching)
            } else {
                self.notchClose()
            }
        }
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
                                self?.notchOpen(galleryItem: .switching)
                            }
                        }
                    } else {
                        notchOpen(galleryItem: .switching)
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
                    if activeIndex < switchItems.count {
                        switchItems[activeIndex].0.hide()
                    }
                case .minimize:
                    if activeIndex < switchItems.count {
                        switchItems[activeIndex].0.minimize()
                    }
                case .close:
                    if activeIndex < switchItems.count {
                        switchItems[activeIndex].0.close()
                    }
                case .quit:
                    if activeIndex < switchItems.count {
                        switchItems[activeIndex].0.quit()
                    }
                case .drop:
                    notchClose()
                    initPointer(pointer: 1)
                    self.state = .none
                }
            }
            .store(in: &cancellables)
    }
    
    func setupCancellables() {
        self.cancellables.removeAll()
        setupEachCancellable(toggleType: .cmdTab, triggeredState: cmdTabTrigger)
        setupEachCancellable(toggleType: .optTab, triggeredState: optTabTrigger)
        setupEachCancellable(toggleType: .cmdBtick, triggeredState: cmdBtickTrigger)
        setupEachCancellable(toggleType: .optBtick, triggeredState: optBtickTrigger)
        let events = EventMonitors.shared
    }
}
