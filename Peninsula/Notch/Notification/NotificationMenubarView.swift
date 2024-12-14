//
//  NotificationMenubarView.swift
//  Island
//
//  Created by Celve on 9/22/24.
//

import SwiftUI

struct NotificationMenubarView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var nm = NotificationModel.shared

    var body: some View {
        HStack {
            if vm.mode == .normal {
                Button(action: {
                    let openPanel = NSOpenPanel()
                    openPanel.canChooseFiles = true
                    openPanel.canChooseDirectories = false
                    openPanel.allowsMultipleSelection = false
                    openPanel.allowedContentTypes = [.application]
                    
                    vm.isExternal = true
                    if openPanel.runModal() == .OK, let appUrl = openPanel.url {
                        vm.isExternal = false
                        guard let appBundle = Bundle(url: appUrl),
                              let appName =
                                (appBundle.infoDictionary?["CFBundleDisplayName"]
                                 ?? appBundle.infoDictionary?["CFBundleName"]) as? String
                        else {
                            return
                        }
                        nm.observe(bundleId: appBundle.bundleIdentifier ?? "")
                    } else {
                        vm.isExternal = false
                    }
                }) {
                    Image(systemName: "plus.square.fill")
                }.buttonStyle(.plain)
                Button(action: {
                    vm.mode = .delete
                }) {
                    Image(systemName: "minus.square.fill")
                }.buttonStyle(.plain)
            } else {
                Button(action: {
                    vm.mode = .normal
                }) {
                    Text("Done")
                }.buttonStyle(.plain)
            }
        }.animation(.spring, value: vm.mode)
    }
}
