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
    var windowControllers: [NotchWindowController] = []
    let notchViewModels: NotchViewModels = NotchViewModels.shared
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
        windowControllers.removeAll()
        notchViewModels.inner.removeAll()
        let screens = NSScreen.screens
        for screen in screens {
            let windowController = NotchWindowController.init(screen: screen, app: app)
            if isFirstOpen, !isLaunchedAtLogin {
                windowController.openAfterCreate = true
            }
            windowControllers.append(windowController)
            notchViewModels.inner.append(windowController.vm)
        }
        HotKeyObserver.shared.start()
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
                  windowController.vm.status == .opened
            else { return }
            window.makeKeyAndOrderFront(nil)
        }
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        for windowController in windowControllers {
            let vm = windowController.vm
            vm.notchOpen(.tray)
        }
        return true
    }
}
