//
//  NotchViewModel+Events.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/8.
//

import Cocoa
import Combine
import Foundation
import SwiftUI

extension NotchViewModel {
    func setupCancellables() {
        let events = EventMonitors.shared
        events.mouseDown
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let mouseLocation: NSPoint = NSEvent.mouseLocation
                if !isExternal {
                    switch status {
                    case .opened:
                        // touch outside, close
                        if !notchOpenedRect.insetBy(dx: inset, dy: inset).contains(mouseLocation) {
                            notchClose()
                            mode = .normal
                            // click where user open the panel
                        } else if headlineOpenedRect.insetBy(dx: inset, dy: inset).contains(
                            mouseLocation)
                        {
                            // for clicking headline which mouse event may handled by another app
                            // open the menu
                            repeat {
                                if let nextValue = ContentType(rawValue: contentType.rawValue + 1) {
                                    contentType = nextValue
                                } else {
                                    contentType = ContentType(rawValue: 0)!
                                }
                            } while contentType == .switching
                            mode = .normal
                        }
                    case .closed, .popping:
                        // touch inside, open
                        if true {
                            if abstractRect.insetBy(dx: inset, dy: inset).contains(mouseLocation) {
                                if nm.displayedName != "" {
                                    nm.open(bundleId: nm.displayedName)
                                } else {
                                    notchOpen(.notification)
                                }
                            } else if notchRect.insetBy(dx: inset, dy: inset).contains(mouseLocation) {
                                notchOpen(.apps)
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)

        events.optionKeyPress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] input in
                guard let self else { return }
                optionKeyPressed = input
            }
            .store(in: &cancellables)
        
        events.hotKeyToggle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] input in
                guard let self else { return }
                switch input {
                case .on:
                    windowsCounter = 1
                    notchOpen(.switching)
                case .forward:
                    windowsCounter += 1
                case .backward:
                    windowsCounter -= 1
                case .off:
                    if self.isFirst {
                        self.isFirst = false
                    } else {
                        notchClose()
                        if windowsPointer < windows.inner.count {
                            windows.inner[windowsPointer].focus()
                        }
                        windowsCounter = 1
                    }
                case .drop:
                    notchClose()
                    windowsCounter = 1
                }
            }
            .store(in: &cancellables)
        
        events.mouseLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mouseLocation in
                guard let self else { return }
                let mouseLocation: NSPoint = NSEvent.mouseLocation
                let aboutToOpen = notchRect.insetBy(dx: inset, dy: inset).contains(mouseLocation)
                if status == .closed, aboutToOpen { notchPop() }
                if status == .popping, !aboutToOpen { notchClose() }
            }
            .store(in: &cancellables)

        $status
            .filter { $0 != .closed }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                withAnimation { self?.notchVisible = true }
            }
            .store(in: &cancellables)

        $status
            .filter { $0 == .popping }
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] _ in
                guard NSEvent.pressedMouseButtons == 0 else { return }
                self?.hapticSender.send()
            }
            .store(in: &cancellables)

        hapticSender
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] _ in
                guard self?.hapticFeedback ?? false else { return }
                NSHapticFeedbackManager.defaultPerformer.perform(
                    .levelChange,
                    performanceTime: .now
                )
            }
            .store(in: &cancellables)

        $status
            .debounce(for: 0.5, scheduler: DispatchQueue.global())
            .filter { $0 == .closed }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                withAnimation {
                    self?.notchVisible = false
                }
            }
            .store(in: &cancellables)

        $selectedLanguage
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] output in
                self?.notchClose()
                output.apply()
            }
            .store(in: &cancellables)
    }

    func destroy() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
