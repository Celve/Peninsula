//
//  NotchView.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//

import SwiftUI

struct NotchHoverView: View {
    @StateObject var notchViewModel: NotchViewModel
    @ObservedObject var notchModel = NotchModel.shared
    
    var body: some View {
        ZStack(alignment: .top) {
            NotchDynamicView(notchViewModel: notchViewModel)
                .zIndex(0)
            Group {
                if notchViewModel.status == .opened {
                    NotchContainerView(vm: notchViewModel)
                        .padding(.top, notchViewModel.deviceNotchRect.height - notchViewModel.spacing + 1)
                        .padding(notchViewModel.spacing)
                        .frame(
                            maxWidth: notchViewModel.notchOpenedSize.width, maxHeight: notchViewModel.notchOpenedSize.height
                        )
                        .zIndex(1)
                }
            }
            .transition(
                .blurReplace
            )
        }
        .onHover { isHover in
            if isHover && (notchViewModel.status == .notched || notchViewModel.status == .sliced) {
                notchViewModel.notchPop()
            } else if !isHover {
                notchViewModel.notchClose()
            }
        }
        .onTapGesture {
            notchViewModel.notchOpen(contentType: .apps)
        }
    }
}

struct NotchView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject var notchModel = NotchModel.shared

    @State var dropTargeting: Bool = false

    var body: some View {
        NotchHoverView(notchViewModel: vm, notchModel: notchModel)
        .animation(
            vm.status == .opened ? vm.innerOnAnimation : vm.innerOffAnimation, value: vm.status
        )
        .animation(vm.normalAnimation, value: vm.contentType)
        .background(dragDetector)
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    var dragDetector: some View {
        RoundedRectangle(cornerRadius: vm.notchCornerRadius)
            .foregroundStyle(Color.black.opacity(0.001))  // fuck you apple and 0.001 is the smallest we can have
            .contentShape(Rectangle())
            .frame(
                width: vm.notchSize.width + vm.dropDetectorRange,
                height: vm.notchSize.height + vm.dropDetectorRange
            )
            .onDrop(of: [.data], isTargeted: $dropTargeting) { _ in true }
            .onChange(of: dropTargeting) { isTargeted in
                if isTargeted, vm.status == .notched {
                    // Open the notch when a file is dragged over it
                    vm.notchOpen(contentType: .tray)
                    vm.hapticSender.send()
                } else if !isTargeted {
                    // Close the notch when the dragged item leaves the area
                    let mouseLocation: NSPoint = NSEvent.mouseLocation
                    if !vm.notchOpenedRect.insetBy(dx: vm.inset, dy: vm.inset).contains(
                        mouseLocation)
                    {
                        vm.notchClose()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
