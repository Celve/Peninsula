//
//  AppDelegate.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//

import AppKit
import Cocoa
import LaunchAtLogin

class AppDelegate: NSObject, NSApplicationDelegate {
    var isFirstOpen = true
    var isLaunchedAtLogin = false
    //    var mainWindowController: NotchWindowController?
    var windowControllers: [NotchWindowController] = []
    var counter = 0

    var timer: Timer?

    func applicationDidFinishLaunching(_: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(rebuildApplicationWindows),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NSApp.setActivationPolicy(.accessory)

        isLaunchedAtLogin = LaunchAtLogin.wasLaunchedAtLogin

        _ = EventMonitors.shared
        let timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            self?.determineIfProcessIdentifierMatches()
            self?.makeKeyAndVisibleIfNeeded()
        }
        self.timer = timer

        rebuildApplicationWindows()
    }

    func applicationWillTerminate(_: Notification) {
        try? FileManager.default.removeItem(at: temporaryDirectory)
        try? FileManager.default.removeItem(at: pidFile)
    }

    func findScreenFitsOurNeeds() -> NSScreen? {
        if let screen = NSScreen.buildin, screen.notchSize != .zero { return screen }
        return .main
    }

    @objc func rebuildApplicationWindows() {
        let app = NSRunningApplication.current
        defer { isFirstOpen = false }
        for windowController in windowControllers {
            windowController.destroy()
        }
        windowControllers = []
        let screens = NSScreen.screens
        for screen in screens {
            let windowController = NotchWindowController.init(screen: screen, app: app)
            if isFirstOpen, !isLaunchedAtLogin {
                windowController.openAfterCreate = true
            }
            windowControllers.append(windowController)
        }
        EventMonitors.shared.hotKeyEvent.start()

        //        if let mainWindowController {
        //            mainWindowController.destroy()
        //        }
        //        mainWindowController = nil
        //        guard let mainScreen = findScreenFitsOurNeeds() else { return }
        //        mainWindowController = .init(screen: mainScreen)
        //        if isFirstOpen, !isLaunchedAtLogin {
        //            mainWindowController?.openAfterCreate = true
        //        }
    }

    func determineIfProcessIdentifierMatches() {
        let pid = String(NSRunningApplication.current.processIdentifier)
        let content = (try? String(contentsOf: pidFile)) ?? ""
        guard
            pid.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                == content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        else {
            NSApp.terminate(nil)
            return
        }
    }

    func makeKeyAndVisibleIfNeeded() {
        for windowController in windowControllers {
            guard let window = windowController.window,
                let vm = windowController.vm,
                vm.status == .opened
            else { return }
            window.makeKeyAndOrderFront(nil)
        }
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        for windowController in windowControllers {
            guard let vm = windowController.vm
            else { return true }
            vm.notchOpen(.tray)
        }
        return true
    }
}
