enum NotchContentType: Int, Codable, Hashable, Equatable {
    case apps
    case timer
    case notification
    case tray
    case traySettings
    case settings
    case switching
    case switchSettings
    case searching
    
    func count() -> Int {
        return 9
    }
    
    func toTitle() -> String { // when modify this, don't forgfet to modify the count of cases
        switch self {
        case .apps:
            return "Apps"
        case .timer:
            return "Timer"
        case .tray:
            return "Tray"
        case .traySettings:
            return "TraySettings"
        case .notification:
            return "Notification"
        case .settings:
            return "Settings"
        case .switching:
            return "Switch"
        case .switchSettings:
            return "SwitchSettings"
        case .searching:
            return "Searching"
        }
    }
    
    func next(invisibles: Dictionary<Self, Self>) -> Self {
        var contentType = self
        if let nextContentType = invisibles[contentType]{
            return nextContentType
        } else {
            repeat {
                if let nextValue = NotchContentType(rawValue: contentType.rawValue + 1) {
                    contentType = nextValue
                } else {
                    contentType = NotchContentType(rawValue: 0) ?? .apps
                }
            } while invisibles.keys.contains(where: { $0 == contentType })
        }
        return contentType
    }

    func previous(invisibles: Dictionary<Self, Self>) -> Self {
        var contentType = self
        if let previousContentType = invisibles[contentType]{
            return previousContentType
        } else {
            repeat {
                if let previousValue = NotchContentType(rawValue: contentType.rawValue - 1) {
                    contentType = previousValue
                } else {
                    contentType = NotchContentType(rawValue: count() - 1) ?? contentType
                }
            } while invisibles.keys.contains(where: { $0 == contentType })
        }
        return contentType
    }
}
