//
//  main.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//

import AppKit

let productPage = URL(string: "https://github.com/Celve/Peninsula")!
let sponsorPage = URL(string: "https://github.com/sponsors/Celve")!

let bundleIdentifier = Bundle.main.bundleIdentifier!
let appVersion =
    "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))"

private let availableDirectories = FileManager
    .default
    .urls(for: .documentDirectory, in: .userDomainMask)
let documentsDirectory = availableDirectories[0]
    .deletingLastPathComponent()
    .appendingPathComponent(".config")
    .appendingPathComponent("peninsula")
let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent(bundleIdentifier)
try? FileManager.default.removeItem(at: temporaryDirectory)
try? FileManager.default.createDirectory(
    at: documentsDirectory,
    withIntermediateDirectories: true,
    attributes: nil
)
try? FileManager.default.createDirectory(
    at: temporaryDirectory,
    withIntermediateDirectories: true,
    attributes: nil
)

let pidFile = documentsDirectory.appendingPathComponent("ProcessIdentifier")

do {
    let prevIdentifier = try String(contentsOf: pidFile, encoding: .utf8)
    if let prev = Int(prevIdentifier) {
        if let app = NSRunningApplication(processIdentifier: pid_t(prev)) {
            app.terminate()
        }
    }
} catch {}
try? FileManager.default.removeItem(at: pidFile)

do {
    let pid = String(NSRunningApplication.current.processIdentifier)
    try pid.write(to: pidFile, atomically: true, encoding: .utf8)
} catch {
    NSAlert.popError(error)
    exit(1)
}

BackgroundWork.start()
_ = Apps.shared

_ = TrayDrop.shared
TrayDrop.shared.cleanExpiredFiles()

_ = NotificationModel.shared
_ = Dock.shared

private let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
_ = AXIsProcessTrustedWithOptions(
    [kAXTrustedCheckOptionPrompt.takeRetainedValue(): false] as CFDictionary)
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
