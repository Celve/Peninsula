import ApplicationServices.HIServices.AXUIElement
import AppKit

class AxWindow: AxElement {
    override init(element: AXUIElement) {
        super.init(element: element)
    }
    
    func cgWindowId() throws -> CGWindowID? {
        var id = CGWindowID(0)
        return try axCallWhichCanThrow(_AXUIElementGetWindow(element, &id), &id)
    }
    
    func level() throws -> CGWindowLevel? {
        var level = CGWindowLevel(0)
        guard let id = try cgWindowId() else { return nil }
        CGSGetWindowLevel(cgsMainConnectionId, id, &level)
        return level
    }
    
    func level(id: CGWindowID) -> CGWindowLevel {
        var level = CGWindowLevel(0)
        CGSGetWindowLevel(cgsMainConnectionId, id, &level)
        return level
    }
    
    func size() throws -> CGSize? {
        return try value(kAXSizeAttribute, CGSize.zero, .cgSize)
    }
    
    func position() throws -> CGPoint? {
        return try value(kAXPositionAttribute, CGPoint.zero, .cgPoint)
    }
    
    func frame() throws -> CGRect? {
        guard let position = try? position() else { return nil };
        guard let size = try? size() else { print("no", position); return nil }
        let result = CGRect(origin: position, size: size)
        return result
    }
    
    func isActual(runningApp: NSRunningApplication) -> Bool {
        guard let cgWid = try? cgWindowId() else { return false }
        guard let subrole = try? subrole() else { return false }
        guard let role = try? role() else { return false }
        guard let title = try? title() else { return false }
        guard let level = try? level() else { return false }
        guard let size = try? size() else { return false }

        return cgWid != 0 && (
            (
                AxWindow.books(runningApp) ||
                AxWindow.keynote(runningApp) ||
                AxWindow.preview(runningApp, subrole) ||
                AxWindow.iina(runningApp) ||
                AxWindow.openFlStudio(runningApp, title) ||
                AxWindow.crossoverWindow(runningApp, role, subrole, level) ||
                AxWindow.isAlwaysOnTopScrcpy(runningApp, level, role, subrole)
            ) || (
                level == CGWindowLevel.normalLevel && (
                    [kAXStandardWindowSubrole, kAXDialogSubrole].contains(subrole) ||
                    AxWindow.openBoard(runningApp) ||
                    AxWindow.adobeAudition(runningApp, subrole) ||
                    AxWindow.adobeAfterEffects(runningApp, subrole) ||
                    AxWindow.steam(runningApp, title, role) ||
                    AxWindow.worldOfWarcraft(runningApp, role) ||
                    AxWindow.battleNetBootstrapper(runningApp, role) ||
                    AxWindow.firefox(runningApp, role, size) ||
                    AxWindow.vlcFullscreenVideo(runningApp, role) ||
                    AxWindow.sanGuoShaAirWD(runningApp) ||
                    AxWindow.dvdFab(runningApp) ||
                    AxWindow.drBetotte(runningApp) ||
                    AxWindow.autocad(runningApp, subrole)
                ) && (
                    AxWindow.mustHaveIfJetbrainApp(runningApp, title, subrole, size) &&
                    AxWindow.mustHaveIfSteam(runningApp, title, role) &&
                    AxWindow.mustHaveIfColorSlurp(runningApp, title, subrole)
                )
            ) || (
                level == CGWindowLevel.mainMenuWindow && AxWindow.arc(runningApp, role)
            )
        )
    }
    
    
    func focus() {
        performAction(action: kAXRaiseAction)
    }
    
    private static func mustHaveIfJetbrainApp(_ runningApp: NSRunningApplication, _ title: String?, _ subrole: String?, _ size: NSSize) -> Bool {
        // jetbrain apps sometimes generate non-windows that pass all checks in isActualWindow
        // they have no title, so we can filter them out based on that
        // we also hide windows too small
        return runningApp.bundleIdentifier?.range(of: "^com\\.(jetbrains\\.|google\\.android\\.studio).*?$", options: .regularExpression) == nil || (
            (subrole == kAXStandardWindowSubrole || (title != nil && title != "")) &&
            size.width > 100 && size.height > 100
        )
    }
    
    private static func mustHaveIfColorSlurp(_ runningApp: NSRunningApplication, _ title: String?, _ subrole: String?) -> Bool {
        return runningApp.bundleIdentifier != "com.IdeaPunch.ColorSlurp" || subrole == kAXStandardWindowSubrole
    }
    
    private static func iina(_ runningApp: NSRunningApplication) -> Bool {
        // IINA.app can have videos float (level == 2 instead of 0)
        // there is also complex animations during which we may or may not consider the window not a window
        return runningApp.bundleIdentifier == "com.colliderli.iina"
    }
    
    private static func keynote(_ runningApp: NSRunningApplication) -> Bool {
        // apple Keynote has a fake fullscreen window when in presentation mode
        // it covers the screen with a AXUnknown window instead of using standard fullscreen mode
        return runningApp.bundleIdentifier == "com.apple.iWork.Keynote"
    }
    
    private static func preview(_ runningApp: NSRunningApplication, _ subrole: String?) -> Bool {
        // when opening multiple documents at once with apple Preview,
        // one of the window will have level == 1 for some reason
        return runningApp.bundleIdentifier == "com.apple.Preview" && [kAXStandardWindowSubrole, kAXDialogSubrole].contains(subrole)
    }
    
    private static func openFlStudio(_ runningApp: NSRunningApplication, _ title: String?) -> Bool {
        // OpenBoard is a ported app which doesn't use standard macOS windows
        return runningApp.bundleIdentifier == "com.image-line.flstudio" && (title != nil && title != "")
    }
    
    private static func openBoard(_ runningApp: NSRunningApplication) -> Bool {
        // OpenBoard is a ported app which doesn't use standard macOS windows
        return runningApp.bundleIdentifier == "org.oe-f.OpenBoard"
    }
    
    private static func adobeAudition(_ runningApp: NSRunningApplication, _ subrole: String?) -> Bool {
        return runningApp.bundleIdentifier == "com.adobe.Audition" && subrole == kAXFloatingWindowSubrole
    }
    
    private static func adobeAfterEffects(_ runningApp: NSRunningApplication, _ subrole: String?) -> Bool {
        return runningApp.bundleIdentifier == "com.adobe.AfterEffects" && subrole == kAXFloatingWindowSubrole
    }
    
    private static func books(_ runningApp: NSRunningApplication) -> Bool {
        // Books.app has animations on window creation. This means windows are originally created with subrole == AXUnknown or isOnNormalLevel == false
        return runningApp.bundleIdentifier == "com.apple.iBooksX"
    }
    
    private static func worldOfWarcraft(_ runningApp: NSRunningApplication, _ role: String?) -> Bool {
        return runningApp.bundleIdentifier == "com.blizzard.worldofwarcraft" && role == kAXWindowRole
    }
    
    private static func battleNetBootstrapper(_ runningApp: NSRunningApplication, _ role: String?) -> Bool {
        // Battlenet bootstrapper windows have subrole == AXUnknown
        return runningApp.bundleIdentifier == "net.battle.bootstrapper" && role == kAXWindowRole
    }
    
    private static func drBetotte(_ runningApp: NSRunningApplication) -> Bool {
        return runningApp.bundleIdentifier == "com.ssworks.drbetotte"
    }
    
    private static func dvdFab(_ runningApp: NSRunningApplication) -> Bool {
        return runningApp.bundleIdentifier == "com.goland.dvdfab.macos"
    }
    
    private static func sanGuoShaAirWD(_ runningApp: NSRunningApplication) -> Bool {
        return runningApp.bundleIdentifier == "SanGuoShaAirWD"
    }
    
    private static func steam(_ runningApp: NSRunningApplication, _ title: String?, _ role: String?) -> Bool {
        // All Steam windows have subrole == AXUnknown
        // some dropdown menus are not desirable; they have title == "", or sometimes role == nil when switching between menus quickly
        return runningApp.bundleIdentifier == "com.valvesoftware.steam" && (title != nil && title != "" && role != nil)
    }
    
    private static func mustHaveIfSteam(_ runningApp: NSRunningApplication, _ title: String?, _ role: String?) -> Bool {
        // All Steam windows have subrole == AXUnknown
        // some dropdown menus are not desirable; they have title == "", or sometimes role == nil when switching between menus quickly
        return runningApp.bundleIdentifier != "com.valvesoftware.steam" || (title != nil && title != "" && role != nil)
    }
    
    private static func firefox(_ runningApp: NSRunningApplication, _ role: String?, _ size: CGSize?) -> Bool {
        // Firefox fullscreen video have subrole == AXUnknown if fullscreen'ed when the base window is not fullscreen
        // Firefox tooltips are implemented as windows with subrole == AXUnknown
        return (runningApp.bundleIdentifier?.hasPrefix("org.mozilla.firefox") ?? false) && role == kAXWindowRole && size?.height != nil && size!.height > 400
    }
    
    private static func vlcFullscreenVideo(_ runningApp: NSRunningApplication, _ role: String?) -> Bool {
        // VLC fullscreen video have subrole == AXUnknown if fullscreen'ed
        return (runningApp.bundleIdentifier?.hasPrefix("org.videolan.vlc") ?? false) && role == kAXWindowRole
    }
    
    private static func crossoverWindow(_ runningApp: NSRunningApplication, _ role: String?, _ subrole: String?, _ level: CGWindowLevel) -> Bool {
        return runningApp.bundleIdentifier == nil && role == kAXWindowRole && subrole == kAXUnknownSubrole && level == CGWindowLevel.normalLevel
        && (runningApp.localizedName == "wine64-preloader" || runningApp.executableURL?.absoluteString.contains("/winetemp-") ?? false)
    }
    
    private static func isAlwaysOnTopScrcpy(_ runningApp: NSRunningApplication, _ level: CGWindowLevel, _ role: String?, _ subrole: String?) -> Bool {
        // scrcpy presents as a floating window when "Always on top" is enabled, so it doesn't get picked up normally.
        // It also doesn't have a bundle ID, so we need to match using the localized name, which should always be the same.
        return runningApp.localizedName == "scrcpy" && level == CGWindowLevel.floatingWindow && role == kAXWindowRole && subrole == kAXStandardWindowSubrole
    }
    
    private static func autocad(_ runningApp: NSRunningApplication, _ subrole: String?) -> Bool {
        // AutoCAD uses the undocumented "AXDocumentWindow" subrole
        return (runningApp.bundleIdentifier?.hasPrefix("com.autodesk.AutoCAD") ?? false) && subrole == kAXDocumentWindowSubrole
    }
    
    private static func arc(_ runningApp: NSRunningApplication, _ role: String?) -> Bool {
        return (runningApp.bundleIdentifier?.hasPrefix("company.thebrowser.Browser") ?? false) && role == kAXWindowRole
    }
}
