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

    var body: some View {
        VStack(spacing: vm.spacing) {
            HStack {
                Picker("Language: ", selection: $vm.selectedLanguage) {
                    ForEach(Language.allCases) { language in
                        Text(language.localized).tag(language)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(
                    width: vm.selectedLanguage == .simplifiedChinese
                        || vm.selectedLanguage == .traditionalChinese ? 220 : 160)

                Spacer()
                LaunchAtLogin.Toggle {
                    Text(NSLocalizedString("Launch at Login", comment: ""))
                }

                Spacer()
                Toggle("Haptic Feedback ", isOn: $vm.hapticFeedback)

                Spacer()
            }

            HStack {
                Text("File Storage Time: ")
                Picker(String(), selection: $tvm.selectedFileStorageTime) {
                    ForEach(TrayDrop.FileStorageTime.allCases) { time in
                        Text(time.localized).tag(time)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 100)
                if tvm.selectedFileStorageTime == .custom {
                    TextField("Days", value: $tvm.customStorageTime, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                        .padding(.leading, 10)
                    Picker("Time Unit", selection: $tvm.customStorageTimeUnit) {
                        ForEach(TrayDrop.CustomstorageTimeUnit.allCases) { unit in
                            Text(unit.localized).tag(unit)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                }
                Spacer()
                Text("")
                Toggle("Faster switch", isOn: $notchModel.fasterSwitch)
                Spacer()
                Text("Accessibility: ")
                Button(action: {
                    if !accessibilityGranted() {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                    }
                }) {
                    Text("Grant")
                }
            }
            .padding()
        }
        .animation(vm.normalAnimation, value: vm.contentType)
        .animation(
            vm.status == .opened ? vm.innerOnAnimation : vm.innerOffAnimation, value: vm.status)
    }
}
