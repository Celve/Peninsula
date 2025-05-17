import Cocoa
import Combine
import Foundation
import LaunchAtLogin
import SwiftUI

class NotchViewModel: NSObject, ObservableObject {
    @ObservedObject var notifModel = NotificationModel.shared
    @ObservedObject var windows = Windows.shared
    @ObservedObject var notchModel = NotchModel.shared
    var cancellables: Set<AnyCancellable> = []
    var windowId: Int
    var window: NSWindow
    let inset: CGFloat
    var isFirst: Bool = true
    var isBuiltin: Bool
    var baseStatus: Status {
        if !isBuiltin && notchModel.smallerNotch {
            .sliced
        } else {
            .notched
        }
    }

    init(inset: CGFloat = -4, window: NSWindow, isBuiltin: Bool) {
        self.isBuiltin = isBuiltin
        self.inset = inset
        self.window = window
        self.windowId = window.windowNumber
        super.init()
        setupCancellables()
    }

    deinit {
        destroy()
    }

    let normalAnimation: Animation = .interactiveSpring(duration: 0.314)
    let outerOnAnimation: Animation = .interactiveSpring(
        duration: 0.314, extraBounce: 0.15, blendDuration: 0.157)
    let innerOnAnimation: Animation = .interactiveSpring(duration: 0.314).delay(0.157)
    let outerOffAnimation: Animation = .spring(duration: 0.236).delay(0.118)
    let innerOffAnimation: Animation = .interactiveSpring(duration: 0.236)

    var notchOpenedSize: CGSize {
        switch contentType {
        case .switching:
            .init(
                width: 600,
                height: CGFloat((notchModel.globalWindowsEnd - notchModel.globalWindowsBegin))
                    * SwitchContentView.HEIGHT
                    + deviceNotchRect.height + spacing * CGFloat(3))
        default:
            .init(width: 600, height: 200 + 1)
        }
    }
    let dropDetectorRange: CGFloat = 32

    enum Status: String, Codable, Hashable, Equatable {
        case sliced
        case notched
        case opened
        case popping
    }

    enum OpenReason: String, Codable, Hashable, Equatable {
        case click
        case drag
        case boot
        case unknown
    }


    enum Mode: Int, Codable, Hashable, Equatable {
        case normal
        case delete
    }

    var notchOpenedRect: CGRect {
        .init(
            x: screenRect.origin.x + (screenRect.width - notchOpenedSize.width) / 2,
            y: screenRect.origin.y + screenRect.height - notchOpenedSize.height,
            width: notchOpenedSize.width,
            height: notchOpenedSize.height
        )
    }

    var abstractSize: CGFloat {
        if status == .opened {
            return 0
        } else {
            let count = notifModel.names.count
            if count == 0 {
                return 0
            } else {
                let spacing = deviceNotchRect.height / 8
                let itemHeight = deviceNotchRect.height
                return spacing + (itemHeight + spacing) * CGFloat(count)
            }
        }
    }

    var headlineOpenedRect: CGRect {
        .init(
            x: screenRect.origin.x + (screenRect.width - notchOpenedSize.width) / 2,
            y: screenRect.origin.y + screenRect.height - deviceNotchRect.height,
            width: notchOpenedSize.width,
            height: deviceNotchRect.height
        )
    }

    var notchSize: CGSize {
        switch status {
        case .sliced:
            return CGSize(
                width: deviceNotchRect.width + abstractSize,
                height: 4
            )
        case .notched:
            var ans = CGSize(
                width: deviceNotchRect.width + abstractSize,
                height: deviceNotchRect.height + 1
            )
            if ans.width < 0 { ans.width = 0 }
            if ans.height < 0 { ans.height = 0 }
            return ans
        case .opened:
            return notchOpenedSize
        case .popping:
            return .init(
                width: deviceNotchRect.width + abstractSize + spacing,
                height: deviceNotchRect.height * 2 + spacing
            )
        }
    }

    var notchRect: CGRect {
        .init(
            x: screenRect.origin.x + (screenRect.width - notchSize.width + abstractSize) / 2,
            y: screenRect.origin.y + screenRect.height - notchSize.height,
            width: notchSize.width,
            height: notchSize.height
        )
    }

    var abstractRect: CGRect {
        .init(
            x: screenRect.origin.x + (screenRect.width + deviceNotchRect.width) / 2,
            y: screenRect.origin.y + screenRect.height - deviceNotchRect.height,
            width: abstractSize,
            height: deviceNotchRect.height
        )
    }

    var notchCornerRadius: CGFloat {
        switch status {
        case .sliced, .notched: 8
        case .opened: 32
        case .popping: 10
        }
    }

    var header: String {
        contentType == .settings
            ? "Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown") (Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"))"
            : "Peninsula"
    }

    @Published private(set) var status: Status = .notched
    @Published var isExternal: Bool = false
    @Published var openReason: OpenReason = .unknown
    @Published var contentType: NotchContentType = NotchContentType(rawValue: 0)!
    @Published var spacing: CGFloat = 16
    @Published var cornerRadius: CGFloat = 16
    @Published var deviceNotchRect: CGRect = .zero
    @Published var screenRect: CGRect = .zero
    @Published var cgScreenRect: CGRect = .zero
    @Published var screenNotchSize: CGSize = .zero
    @Published var optionKeyPressed: Bool = false
    @Published var notchVisible: Bool = true
    @Published var mode: Mode = .normal

    @PublishedPersist(key: "selectedLanguage", defaultValue: .system)
    var selectedLanguage: Language

    @PublishedPersist(key: "hapticFeedback", defaultValue: true)
    var hapticFeedback: Bool

    let hapticSender = PassthroughSubject<Void, Never>()

    func notchOpen(contentType: NotchContentType) {
        openReason = .unknown
        status = .opened
        self.contentType = contentType
    }
    
    func notchClose() {
        openReason = .unknown
        status = baseStatus
    }

    func notchPop() {
        openReason = .unknown
        status = .popping
    }
}
