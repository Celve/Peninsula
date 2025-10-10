//
//  NotchSettingsView.swift
//  NotchDrop
//
//  Created by 曹丁杰 on 2024/7/29.
//

import LaunchAtLogin
import SwiftUI

func accessibilityGranted() -> Bool {
    return AXIsProcessTrustedWithOptions(
        [kAXTrustedCheckOptionPrompt.takeRetainedValue(): false] as CFDictionary)
}


struct SettingsView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var notchModel = NotchModel.shared
    @StateObject var tvm: TrayDrop = .shared
    @ObservedObject var galleryModel = GalleryModel.shared

    var body: some View {
        VStack(spacing: vm.spacing) {
            HStack {
                Button(action: {
                    notchModel.updaterController.updater.checkForUpdates()
                }) {
                    Text("Check for updates")
                }
                Text("Accessibility: ")
                Button(action: {
                    if !accessibilityGranted() {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }) {
                    Text("Grant")
                }
                Text("Exit: ")
                Button(action: {
                    vm.notchClose()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        NSApp.terminate(nil)
                    }
                }) {
                    Text("X")
                }
            }
            HStack {
                Spacer()
                Toggle("Haptic Feedback ", isOn: $vm.hapticFeedback)
                LaunchAtLogin.Toggle {
                    Text(NSLocalizedString("Launch at Login", comment: ""))
                }
                Spacer()
                Toggle("Faster switch", isOn: $notchModel.fasterSwitch)
                Spacer()
                Toggle("Smaller notch", isOn: $notchModel.smallerNotch)
                Spacer()
            }
            .padding()
        }
        .animation(vm.normalAnimation, value: galleryModel.currentItem)
        .animation(
            vm.status == .opened ? vm.innerOnAnimation : vm.innerOffAnimation, value: vm.status)
    }
}
