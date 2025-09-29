//
//  NotchWindowController.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//

import Cocoa

private let notchHeight: CGFloat = 800
private let notchWidth: CGFloat = 150

class NotchWindowController: NSWindowController {
    var vm: NotchViewModel
    weak var screen: NSScreen?

    var openAfterCreate: Bool = false

    init(window: NSPanel, screen: NSScreen) {
        var notchSize = screen.notchSize
        let vm = NotchViewModel(inset: -4, window: window, isBuiltin: notchSize != .zero)
        self.vm = vm
        self.screen = screen
        window.orderFrontRegardless()
        super.init(window: window)

        contentViewController = NotchViewController(vm)

        if notchSize == .zero {
            notchSize = .init(width: notchWidth, height: 24)
        }
        vm.deviceNotchRect = CGRect(
            x: screen.frame.origin.x + (screen.frame.width - notchSize.width) / 2,
            y: screen.frame.origin.y + screen.frame.height - notchSize.height,
            width: notchSize.width,
            height: notchSize.height
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak vm] in
            vm?.screenRect = screen.frame
            vm?.cgScreenRect = screen.frame
            if let primaryFrame = NSScreen.screens.first?.frame {
                vm?.cgScreenRect.origin.y = NSMaxY(primaryFrame) - NSMaxY(screen.frame)
            }
//            if self.openAfterCreate { vm?.notchOpen(contentType: .tray) }
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    convenience init(screen: NSScreen, app: NSRunningApplication) {
        let window = NotchWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        self.init(window: window, screen: screen)

        let topRect = CGRect(
            x: screen.frame.origin.x,
            y: screen.frame.origin.y + screen.frame.height - notchHeight + 1,
            width: screen.frame.width,
            height: notchHeight
        )
        
        // set content size first, otherwise whether it expands from top-right or from bottom-left is inconsistent between macOS major versions
        window.setContentSize(topRect.size)
        window.setFrameOrigin(topRect.origin)
    }

    deinit {
        destroy()
    }

    func destroy() {
        vm.destroy()
        window?.close()
        contentViewController = nil
        window = nil
    }
}
