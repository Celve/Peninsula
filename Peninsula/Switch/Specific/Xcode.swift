//
//  Xcode.swift
//  Peninsula
//
//  Created by Linyu Wu on 12/25/24.
//
import Foundation
import Cocoa
import AppKit
import ApplicationServices.HIServices

class XcodeWindow {
    let app: Application
    let window: Window
    var observer: AXObserver? = nil
    static let notifications = [
        kAXCreatedNotification
    ]
    
    init(app: Application, window: Window) {
        self.app = app
        self.window = window
        guard let children = try? window.axWindow.children() else { return }
        let splitGroup = children[0]
        guard let children = try? splitGroup.children() else { return }
        let group = children[2]
        guard let children = try? group.children() else { return }
        let splitGroup1 = children[0]
        guard let children = try? splitGroup1.children() else { return }
        let splitGroup2 = children[0]
        guard let children = try? splitGroup2.children() else { return }
        let group1 = children[0]
        guard let children = try? group1.children() else { return }
        let tabBar = children[1]
        guard let children = try? tabBar.children() else { return }
        let tabGroup = children[0]
        guard let children = try? tabGroup.children() else { return }
        let scrollView = children[0]
        guard let children = try? scrollView.children() else { return }
        children[0].performAction(action: kAXPressAction)
    }
    
    func addObserver(element: AxElement) {
        let callback: @convention(c) (AXObserver, AXUIElement, CFString, UnsafeMutableRawPointer?) -> Void = { observer, element, notification, ref in
            let this = Unmanaged<Window>.fromOpaque(ref!).takeUnretainedValue()
            retryAxCallUntilTimeout { try this.handleEvent(notificationType: notification as String, element: element) }
        }
        
        AXObserverCreate(app.pid, callback, &observer)
        guard let observer = observer else { return }
//        for notification in ArcWindow.notifications {
//            retryAxCallUntilTimeout { [weak self] in
//                guard let self = self else { return }
//                let ref = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
//                try self.window.axWindow.subscribeToNotification(observer, notification, ref)
//            }
//        }
//        CFRunLoopAddSource(BackgroundWork.accessibilityEventsThread.runLoop, AXObserverGetRunLoopSource(observer), .defaultMode)
    }
    
    func handleEvent(notificationType: String, element: AXUIElement) throws {
        print(notificationType)
    }
}
