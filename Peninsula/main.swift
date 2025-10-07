//
//  main.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//

import AppKit

let productPage = URL(string: "https://github.com/Celve/Peninsula")
let sponsorPage = URL(string: "https://github.com/sponsors/Celve")

let bundleIdentifier = Bundle.main.bundleIdentifier ?? "Peninsula"
let appVersion =
    "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))"
PeninsulaLog.lifecycle.notice("Launching Peninsula \(appVersion, privacy: .public)")

private let availableDirectories = FileManager
    .default
    .urls(for: .documentDirectory, in: .userDomainMask)
let documentsDirectory = (availableDirectories.first
    ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents"))
    .deletingLastPathComponent()
    .appendingPathComponent(".config")
    .appendingPathComponent("peninsula")
let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent(bundleIdentifier)

if FileManager.default.fileExists(atPath: temporaryDirectory.path) {
    do {
        try FileManager.default.removeItem(at: temporaryDirectory)
    } catch {
        PeninsulaLog.persistence.error("Failed to clear temporary directory", error: error)
    }
}
do {
    try FileManager.default.createDirectory(
        at: documentsDirectory,
        withIntermediateDirectories: true,
        attributes: nil
    )
} catch {
    PeninsulaLog.persistence.error("Failed to ensure documents directory", error: error)
}
do {
    try FileManager.default.createDirectory(
        at: temporaryDirectory,
        withIntermediateDirectories: true,
        attributes: nil
    )
} catch {
    PeninsulaLog.persistence.error("Failed to ensure temporary directory", error: error)
}

let pidFile = documentsDirectory.appendingPathComponent("ProcessIdentifier")

do {
    let prevIdentifier = try String(contentsOf: pidFile, encoding: .utf8)
    if let prev = Int(prevIdentifier) {
        if let app = NSRunningApplication(processIdentifier: pid_t(prev)) {
            app.terminate()
            PeninsulaLog.lifecycle.info("Terminated previous Peninsula process pid=\(prev, privacy: .public)")
        }
    }
} catch {}
do {
    try FileManager.default.removeItem(at: pidFile)
} catch {}

do {
    let pid = String(NSRunningApplication.current.processIdentifier)
    try pid.write(to: pidFile, atomically: true, encoding: .utf8)
} catch {
    PeninsulaLog.persistence.error("Failed to write PID file", error: error)
    NSAlert.popError(error)
    exit(1)
}

BackgroundWork.start()
_ = Apps.shared

_ = TrayDrop.shared
TrayDrop.shared.cleanExpiredFiles()

_ = NotificationModel.shared
_ = Dock.shared
PeninsulaLog.lifecycle.notice("Peninsula initialized")

private let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
_ = AXIsProcessTrustedWithOptions(
    [kAXTrustedCheckOptionPrompt.takeRetainedValue(): false] as CFDictionary)
PeninsulaLog.lifecycle.notice("Accessibility trust check requested")
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
