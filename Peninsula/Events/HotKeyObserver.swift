import AppKit
import Carbon.HIToolbox
import Cocoa
import Combine
import Foundation
import SwiftUI

enum HotKeyEvent {
    case on
    case forward
    case backward
    case quit
    case close
    case minimize
    case hide
    case off
    case drop
}

enum HotKeyState {
    case none
    case cmdBtick
    case cmdTab
    case optBtick
    case optTab
    
    func isCmd() -> Bool {
        return self == .cmdBtick || self == .cmdTab
    }
    
    func getKeyCode() -> Int {
        if self == .cmdBtick || self == .optBtick {
            return Key.backtick.rawValue
        } else {
            return Key.tab.rawValue
        }
    }
}

func onlyCmd(_ flags: CGEventFlags) -> Bool {
    return flags.contains(.maskCommand) && !flags.contains(.maskAlternate)
}

func onlyOption(_ flags: CGEventFlags) -> Bool {
    return !flags.contains(.maskCommand) && flags.contains(.maskAlternate)
}

class HotKeyToggle {
    let toggle: CurrentValueSubject<HotKeyEvent, Never> = .init(.off)
    let state: HotKeyState
    
    init(state: HotKeyState) {
        self.state = state
    }
    
    func checkFlags(_ flags: CGEventFlags) -> Bool {
        if self.state.isCmd() {
            return onlyCmd(flags)
        } else {
            return onlyOption(flags)
        }
    }
    
    func process(globalState: inout HotKeyState, type: CGEventType, keyCode: Int, flags: CGEventFlags) -> Bool {
        if type == .keyDown {
            if globalState == .none && checkFlags(flags) && keyCode == state.getKeyCode() {
                globalState = self.state
                toggle.send(.on)
                return true
            }
            if globalState == state && checkFlags(flags) && keyCode == state.getKeyCode() {
                toggle.send(.forward)
                return true
            }
            if globalState == state && checkFlags(flags) && keyCode == Key.escape.rawValue {
                globalState = .none
                toggle.send(.drop)
                return true
            }
            if globalState == state && checkFlags(flags) && keyCode == Key.q.rawValue {
                toggle.send(.quit)
                return true
            }
            if globalState == state && checkFlags(flags) && keyCode == Key.w.rawValue {
                toggle.send(.close)
                return true
            }
            if globalState == state && checkFlags(flags) && keyCode == Key.m.rawValue {
                toggle.send(.minimize)
                return true
            }
            if globalState == state && checkFlags(flags) && keyCode == Key.h.rawValue {
                toggle.send(.hide)
                return true
            }
        }
        if type == .flagsChanged {
            if globalState == state && !checkFlags(flags) {
                globalState = .none
                toggle.send(.off)
                return true
            }
            if globalState == state && checkFlags(flags) && flags.contains(.maskShift) {
                toggle.send(.backward)
                return true
            }
        }
        return false
    }
}

class HotKeyObserver {
    static let shared = HotKeyObserver()
    let signature = "peninsula".utf16.reduce(0) { ($0 << 8) + OSType($1) }
    let shortcutEventTarget = GetEventDispatcherTarget()
    var hotKeyPressedEventHandler: EventHandlerRef?
    var hotKeyReleasedEventHandler: EventHandlerRef?
    var shortcutsReference: EventHotKeyRef?
    var localMonitor: Any?
    var eventTap: CFMachPort?
    let cmdBtickTogggle = HotKeyToggle(state: .cmdBtick)
    let cmdTabToggle = HotKeyToggle(state: .cmdTab)
    let optBtickTogggle = HotKeyToggle(state: .optBtick)
    let optTabToggle = HotKeyToggle(state: .optTab)
    var toggles: [HotKeyToggle] = []
    var state: HotKeyState = .none
    
    init() {
        toggles = [cmdBtickTogggle, cmdTabToggle, optBtickTogggle, optTabToggle]
    }

    func start() {
        // Use an unmanaged pointer to pass the CurrentValueSubject instance
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        // Remove source if exists
        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }

        let eventMask =
            (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Retrieve the CurrentValueSubject instance from the unmanaged pointer
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let this = Unmanaged<HotKeyObserver>.fromOpaque(refcon).takeUnretainedValue()
                
                if (type == .tapDisabledByUserInput || type == .tapDisabledByTimeout) {
                    if let eventTap = this.eventTap {
                        CGEvent.tapEnable(tap: eventTap, enable: true)
                    }
                } else {
                    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                    let flags = event.flags
                    for toggle in this.toggles {
                        if toggle.process(globalState: &this.state, type: type, keyCode: Int(keyCode), flags: flags) {
                            return nil
                        }
                    }
                }

                return Unmanaged.passRetained(event)
            }, userInfo: selfPointer)

        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            PeninsulaLog.hotKey.error("Failed to create event tap")
        }
    }
}
