//
//  NotchContainerView.swift
//  Island
//
//  Created by Celve on 9/21/24.
//

import ColorfulX
import SwiftUI
import UniformTypeIdentifiers

struct NotchContainerView: View {
    @StateObject var vm: NotchViewModel
    var headline: some View {
        Text("\(vm.contentType.toTitle())").contentTransition(.numericText())
    }
    
    var menubar: some View {
        ZStack {
            switch vm.contentType {
            case .notification:
                NotificationMenubarView(vm: vm)
            default:
                EmptyView()
            }
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: vm.spacing) {
            HeaderView(headline: headline, menubar: menubar)
                .animation(vm.normalAnimation, value: vm.contentType)
                .animation(vm.status == .opened ? vm.innerOnAnimation : vm.innerOffAnimation, value: vm.status)
            switch vm.contentType {
            case .tray:
                HStack(spacing: vm.spacing) {
                    TrayView(vm: vm)
                        .animation(vm.normalAnimation, value: vm.contentType)
                        .animation(vm.status == .opened ? vm.innerOnAnimation : vm.innerOffAnimation, value: vm.status)
                }
            case .menu:
                MenuView(vm: vm).transition(.blurReplace)
            case .apps:
                AppsContentView(vm: vm).transition(.blurReplace)
                    .animation(vm.normalAnimation, value: vm.contentType)
                    .animation(vm.status == .opened ? vm.innerOnAnimation : vm.innerOffAnimation, value: vm.status)
            case .notification:
                NotificationContentView(nvm: vm).transition(.blurReplace)
            case .settings:
                SettingsView(vm: vm).transition(.blurReplace)
            case .switching:
                SwitchContentView(nvm: vm).transition(.blurReplace)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .transition(.blurReplace)
    }
}

