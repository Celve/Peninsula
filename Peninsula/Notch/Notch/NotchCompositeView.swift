//
//  NotchCompositeView.swift
//  Island
//
//  Created by Celve on 9/21/24.
//

import ColorfulX
import SwiftUI
import UniformTypeIdentifiers

struct NotchCompositeView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject var windows = Windows.shared
    @ObservedObject var galleryModel = GalleryModel.shared
    var headline: some View {
        Text("\(galleryModel.currentItem.toTitle())").contentTransition(.numericText())
    }
    
    var menubar: some View {
        ZStack {
            switch galleryModel.currentItem {
            case .notification:
                NotificationMenubarView(vm: vm)
            case .tray:
                TrayDropMenubarView()
            case .apps:
                SwitchMenubarView()
            default:
                EmptyView()
            }
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: vm.spacing) {
            HeaderView(headline: headline, menubar: menubar)
                .animation(vm.normalAnimation, value: galleryModel.currentItem)
                .animation(vm.status == .opened ? vm.innerOnAnimation : vm.innerOffAnimation, value: vm.status)
            switch galleryModel.currentItem {
            case .timer:
                TimerMenuView(notchViewModel: vm)
            case .tray:
                HStack(spacing: vm.spacing) {
                    TrayView(vm: vm)
                        .animation(vm.normalAnimation, value: galleryModel.currentItem)
                        .animation(vm.status == .opened ? vm.innerOnAnimation : vm.innerOffAnimation, value: vm.status)
                }
            case .traySettings:
                TryDropSettingsView(notchViewModel: vm, trayDrop: TrayDrop.shared)
            case .apps:
                AppsView(vm: vm, appsViewModel: galleryModel.appsViewModel).transition(.blurReplace)
                    .animation(vm.normalAnimation, value: galleryModel.currentItem)
                    .animation(vm.status == .opened ? vm.innerOnAnimation : vm.innerOffAnimation, value: vm.status)
            case .notification:
                NotificationContentView(notchViewModel: vm).transition(.blurReplace)
            case .settings:
                SettingsView(vm: vm).transition(.blurReplace)
            case .switching:
                SwitchContentView(notchViewModel: vm).transition(.blurReplace)
            case .switchSettings:
                SwitchSettingView(notchViewModel: vm).transition(.blurReplace)
            case .searching:
                SwitchSearchView(notchViewModel: vm).transition(.blurReplace)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .transition(.blurReplace)
    }
}
