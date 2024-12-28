import AppKit
import ScriptingBridge

public enum ArcScripting: String {
    case application = "application"
    case space = "space"
    case tab = "tab"
    case window = "window"
}

@objc public protocol SBObjectProtocol: NSObjectProtocol {
    func get() -> Any!
}

@objc public protocol SBApplicationProtocol: SBObjectProtocol {
    func activate()
    var delegate: SBApplicationDelegate! { get set }
    var isRunning: Bool { get }
}

// MARK: ArcGenericMethods
@objc public protocol ArcScriptingGenericMethods {
    @objc optional func close() // Close
    @objc optional func select() // Select the tab.
    @objc optional func goBack() // Go Back (If Possible).
    @objc optional func goForward() // Go Forward (If Possible).
    @objc optional func reload() // Reload a tab.
    @objc optional func stop() // Stop the current tab from loading.
    @objc optional func executeJavascript(_ javascript: String!) -> String // Execute a piece of javascript.
    @objc optional func focus() // Focus on a space.
}

// MARK: ArcApplication
@objc public protocol ArcScriptingApplication: SBApplicationProtocol {
    @objc optional func windows() -> SBElementArray
    @objc optional func tabs() -> SBElementArray
    @objc optional var name: String { get } // The name of the application.
    @objc optional var frontmost: Bool { get } // Is this the frontmost (active) application?
    @objc optional var version: String { get } // The version of the application.
}
extension SBApplication: ArcScriptingApplication {}

// MARK: ArcWindow
@objc public protocol ArcScriptingWindow: SBObjectProtocol, ArcScriptingGenericMethods {
    @objc optional func tabs() -> SBElementArray
    @objc optional func spaces() -> SBElementArray
    @objc optional func id() -> String // The unique identifier of the window.
    @objc optional var name: String { get } // The full title of the window.
    @objc optional var index: Int { get } // The index of the window, ordered front to back.
    @objc optional var closeable: Bool { get } // Whether the window has a close box.
    @objc optional var minimizable: Bool { get } // Whether the window can be minimized.
    @objc optional var minimized: Bool { get } // Whether the window is currently minimized.
    @objc optional var resizable: Bool { get } // Whether the window can be resized.
    @objc optional var visible: Bool { get } // Whether the window is currently visible.
    @objc optional var zoomable: Bool { get } // Whether the window can be zoomed.
    @objc optional var zoomed: Bool { get } // Whether the window is currently zoomed.
    @objc optional var activeTab: ArcScriptingTab { get } // Returns the currently selected tab
    @objc optional var activeSpace: ArcScriptingSpace { get } // Returns the currently active space
    @objc optional var incognito: Bool { get } // Whether the window is an incognito window.
    @objc optional var mode: String { get } // Represents the mode of the window which can be 'normal' or 'incognito', can be set only once during creation of the window.
    @objc optional func setIndex(_ index: Int) // The index of the window, ordered front to back.
    @objc optional func setMinimized(_ minimized: Bool) // Whether the window is currently minimized.
    @objc optional func setVisible(_ visible: Bool) // Whether the window is currently visible.
    @objc optional func setZoomed(_ zoomed: Bool) // Whether the window is currently zoomed.
    @objc optional func setIncognito(_ incognito: Bool) // Whether the window is an incognito window.
    @objc optional func setMode(_ mode: String!) // Represents the mode of the window which can be 'normal' or 'incognito', can be set only once during creation of the window.
}
extension SBObject: ArcScriptingWindow {}

// MARK: ArcTab
@objc public protocol ArcScriptingTab: SBObjectProtocol, ArcScriptingGenericMethods {
    @objc optional func id() -> String // The unique identifier of the tab.
    @objc optional var title: String { get } // The full title of the tab.
    @objc optional var URL: String { get } // The url of the tab.
    @objc optional var loading: Bool { get } // Is loading?
    @objc optional var location: String { get } // Represents the location of the tab in the sidebar. Can be 'topApp', 'pinned', or 'unpinned'.
    @objc optional func setURL(_ URL: String!) // The url of the tab.
    @objc optional func setLocation(_ location: String!) // Represents the location of the tab in the sidebar. Can be 'topApp', 'pinned', or 'unpinned'.
}
extension SBObject: ArcScriptingTab {}

// MARK: ArcSpace
@objc public protocol ArcScriptingSpace: SBObjectProtocol, ArcScriptingGenericMethods {
    @objc optional func tabs() -> SBElementArray
    @objc optional func id() -> String // The unique identifier of the space.
    @objc optional var title: String { get } // The full title of the space.
}
extension SBObject: ArcScriptingSpace {}

