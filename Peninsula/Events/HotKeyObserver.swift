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
    case off
    case drop
}

class HotKeyObserver {
    let signature = "peninsula".utf16.reduce(0) { ($0 << 8) + OSType($1) }
    let shortcutEventTarget = GetEventDispatcherTarget()
    var hotKeyPressedEventHandler: EventHandlerRef?
    var hotKeyReleasedEventHandler: EventHandlerRef?
    var shortcutsReference: EventHotKeyRef?
    var localMonitor: Any!
    var eventTap: CFMachPort?
    var hotKeyToggle: CurrentValueSubject<HotKeyEvent, Never>
    var state: Bool = false

    init(hotKeyToggle: CurrentValueSubject<HotKeyEvent, Never>) {
        self.hotKeyToggle = hotKeyToggle
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
                let this = Unmanaged<HotKeyObserver>.fromOpaque(refcon!).takeUnretainedValue()

                if type == .keyDown {
                    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                    let flags = event.flags
                    if keyCode == Key.tab.rawValue && flags.contains(.maskCommand) {
                        if !this.state {
                            this.state = true
                            this.hotKeyToggle.send(.on)
                        } else {
                            this.hotKeyToggle.send(.forward)
                        }
                        return nil
                    } else if keyCode == Key.escape.rawValue && flags.contains(.maskCommand)
                        && this.state
                    {
                        this.state = false
                        this.hotKeyToggle.send(.drop)
                        return nil
                    }
                }

                if type == .flagsChanged && this.state == true {
                    let flags = event.flags
                    if !flags.contains(.maskCommand) {
                        this.state = false
                        this.hotKeyToggle.send(.off)
                        return nil
                    }
                    if flags.contains(.maskShift) {
                        this.hotKeyToggle.send(.backward)
                        return nil
                    }
                }
                return Unmanaged.passRetained(event)
            }, userInfo: selfPointer)

        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            print("Failed to create event tap")
        }
    }
}
