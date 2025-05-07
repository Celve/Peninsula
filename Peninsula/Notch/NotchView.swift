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
                // Make the window key when hovering over the notch
                if let window = NSApp.windows.first(where: { $0.windowNumber == notchViewModel.windowId }) {
                    window.makeKey()
                }
                notchViewModel.notchPop()
                self.notchViewModel.hapticSender.send()
            } else if !isHover {
                // Make the window not key when mouse leaves the notch
                if let window = NSApp.windows.first(where: { $0.windowNumber == notchViewModel.windowId }) {
                    window.resignKey()
                }
                notchViewModel.notchClose()
            }
        }
        .onTapGesture {
            notchViewModel.notchOpen(contentType: .apps)
        }
    }
}

struct NotchView: View {
    @StateObject var notchViewModel: NotchViewModel
    @ObservedObject var notchModel = NotchModel.shared

    @State var dropTargeting: Bool = false

    var body: some View {
        NotchHoverView(notchViewModel: notchViewModel, notchModel: notchModel)
        .animation(
            notchViewModel.status == .opened ? notchViewModel.innerOnAnimation : notchViewModel.innerOffAnimation, value: notchViewModel.status
        )
        .animation(notchViewModel.normalAnimation, value: notchViewModel.contentType)
        .background(dragDetector)
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    var dragDetector: some View {
        RoundedRectangle(cornerRadius: notchViewModel.notchCornerRadius)
            .foregroundStyle(Color.black.opacity(0.001))  // fuck you apple and 0.001 is the smallest we can have
            .contentShape(Rectangle())
            .frame(
                width: notchViewModel.notchSize.width + notchViewModel.dropDetectorRange,
                height: notchViewModel.notchSize.height + notchViewModel.dropDetectorRange
            )
            .onDrop(of: [.data], isTargeted: $dropTargeting) { _ in true }
            .onChange(of: dropTargeting) { isTargeted in
                if isTargeted, notchViewModel.status == .notched {
                    // Open the notch when a file is dragged over it
                    notchViewModel.notchOpen(contentType: .tray)
                    notchViewModel.hapticSender.send()
                } else if !isTargeted {
                    // Close the notch when the dragged item leaves the area
                    let mouseLocation: NSPoint = NSEvent.mouseLocation
                    if !notchViewModel.notchOpenedRect.insetBy(dx: notchViewModel.inset, dy: notchViewModel.inset).contains(
                        mouseLocation)
                    {
                        notchViewModel.notchClose()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
