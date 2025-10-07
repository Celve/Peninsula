import Foundation
import OSLog

enum PeninsulaLog {
    static let subsystem = Bundle.main.bundleIdentifier ?? "Celve.Peninsula"

    static let lifecycle = Logger(subsystem: subsystem, category: "Lifecycle")
    static let window = Logger(subsystem: subsystem, category: "Window")
    static let app = Logger(subsystem: subsystem, category: "App")
    static let accessibility = Logger(subsystem: subsystem, category: "Accessibility")
    static let hotKey = Logger(subsystem: subsystem, category: "HotKey")
    static let tray = Logger(subsystem: subsystem, category: "Tray")
    static let notification = Logger(subsystem: subsystem, category: "Notification")
    static let badge = Logger(subsystem: subsystem, category: "Badge")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
}

extension Logger {
    func error(_ message: StaticString, error: Error) {
        self.error("\(String(describing: message), privacy: .public) error=\(String(describing: error), privacy: .public)")
    }

    func warn(_ message: String) {
        self.warning("\(message, privacy: .public)")
    }
}
