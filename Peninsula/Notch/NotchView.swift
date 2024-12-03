//
//  NotchView.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//

import SwiftUI

struct NotchView: View {
    @StateObject var vm: NotchViewModel

    @State var dropTargeting: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            NotchDynamicView(vm: vm)
                .zIndex(0)
                .disabled(true)
            Group {
                if vm.status == .opened {
                    NotchContainerView(vm: vm)
                        .padding(.top, vm.deviceNotchRect.height - vm.spacing + 1)
                        .padding(vm.spacing)
                        .frame(maxWidth: vm.notchOpenedSize.width, maxHeight: vm.notchOpenedSize.height)
                        .zIndex(1)
                }
            }
            .transition(
                .blurReplace
            )
        }
        .animation(vm.status == .opened ? vm.innerOnAnimation : vm.innerOffAnimation, value: vm.status)
        .animation(vm.normalAnimation, value: vm.contentType)
        .background(dragDetector)
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    var dragDetector: some View {
        RoundedRectangle(cornerRadius: vm.notchCornerRadius)
            .foregroundStyle(Color.black.opacity(0.001)) // fuck you apple and 0.001 is the smallest we can have
            .contentShape(Rectangle())
            .frame(width: vm.notchSize.width + vm.dropDetectorRange, height: vm.notchSize.height + vm.dropDetectorRange)
            .onDrop(of: [.data], isTargeted: $dropTargeting) { _ in true }
            .onChange(of: dropTargeting) { isTargeted in
                if isTargeted, vm.status == .closed {
                    // Open the notch when a file is dragged over it
                    vm.notchOpen(.tray)
                    vm.hapticSender.send()
                } else if !isTargeted {
                    // Close the notch when the dragged item leaves the area
                    let mouseLocation: NSPoint = NSEvent.mouseLocation
                    if !vm.notchOpenedRect.insetBy(dx: vm.inset, dy: vm.inset).contains(mouseLocation) {
                        vm.notchClose()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
