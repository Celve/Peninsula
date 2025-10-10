import SwiftUI

struct GalleryType {
    var size: CGSize
    var displayed: Bool
}

enum GalleryItem: Int, Codable, Hashable, Equatable {
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
        case .apps: return "Apps"
        case .timer: return "Timer"
        case .tray: return "Tray"
        case .traySettings: return "TraySettings"
        case .notification: return "Notification"
        case .settings: return "Settings"
        case .switching: return "Switch"
        case .switchSettings: return "SwitchSettings"
        case .searching: return "Searching"
        }
    }
    
    func next() -> Self {
        return Self(rawValue: self.rawValue + 1) ?? .apps
    }

    func previous() -> Self {
        return Self(rawValue: self.rawValue - 1) ?? .searching
    }
}


class GalleryModel: ObservableObject { 
    static let shared = GalleryModel()

    let appsViewModel: AppsViewModel = AppsViewModel()
//    let timerMenuViewModel: TimerMenuViewModel = TimerMenuViewModel()
//    let trayViewModel: TrayViewModel = TrayViewModel()
//    let notificationViewModel: NotificationViewModel = NotificationViewModel()
//    let settingsViewModel: SettingsViewModel = SettingsViewModel()
//
//    let appsSettingViewModel: AppsSettingViewModel = AppsSettingViewModel()
//    let traySettingViewModel: TraySettingViewModel = TraySettingViewModel()
//    let notificationSettingViewModel: NotificationSettingViewModel = NotificationSettingViewModel()

    @Published var currentItem: GalleryItem = .apps
    
    func next() {
        while true {
            currentItem = currentItem.next()
            if currentItem != .switching && currentItem != .switchSettings && currentItem != .searching && currentItem != .traySettings {
                break
            }
        }
    }
}
