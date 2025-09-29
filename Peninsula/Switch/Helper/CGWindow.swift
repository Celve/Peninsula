import Cocoa

typealias CGWindow = [CFString: Any]

extension CGWindowLevel {
    static let normalLevel = CGWindowLevelForKey(.normalWindow)
    static let floatingWindow = CGWindowLevelForKey(.floatingWindow)
    static let mainMenuWindow = CGWindowLevelForKey(.mainMenuWindow)
}

extension CGWindowID {
    func title() -> String? {
        cgProperty("kCGSWindowTitle", String.self)
    }

    func level() throws -> CGWindowLevel {
        var level = CGWindowLevel(0)
        CGSGetWindowLevel(cgsMainConnectionId, self, &level)
        return level
    }

    func spaces() -> [CGSSpaceID] {
        let cfArray = CGSCopySpacesForWindows(
            cgsMainConnectionId,
            CGSSpaceMask.all.rawValue,
            [self] as CFArray
        )
        if let array = cfArray as? [CGSSpaceID] {
            return array
        }
        if let anyArray = cfArray as? [Any] {
            return anyArray.compactMap { $0 as? CGSSpaceID }
        }
        return []
    }

    func screenshot(_ bestResolution: Bool = false) -> CGImage? {
        // CGSHWCaptureWindowList
        var windowId_ = self
        let cfArray = CGSHWCaptureWindowList(
            cgsMainConnectionId,
            &windowId_,
            1,
            [.ignoreGlobalClipShape, bestResolution ? .bestResolution : .nominalResolution]
        ).takeRetainedValue()
        if let list = cfArray as? [CGImage] {
            return list.first
        }
        return nil
    }

    private func cgProperty<T>(_ key: String, _ type: T.Type) -> T? {
        var value: AnyObject?
        CGSCopyWindowProperty(cgsMainConnectionId, self, key as CFString, &value)
        return value as? T
    }
}
