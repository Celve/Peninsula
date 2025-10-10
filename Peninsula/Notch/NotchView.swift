//
//  NotchView.swift
//  NotchDrop
//
//  Created by 秋星桥 on 2024/7/7.
//

import SwiftUI
import AppKit

struct NotchHoverView: View {
    @ObservedObject var notchViewModel: NotchViewModel
    @ObservedObject var notchModel = NotchModel.shared
    @State private var isHovering: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            NotchBackgroundView(notchViewModel: notchViewModel)
                .zIndex(0)
                .overlay {
                    if notchViewModel.status == .notched {
                        LiveView(notchViewModel: notchViewModel)
                            .padding(.horizontal, notchViewModel.cornerRadius / 2)
                            .offset(x: notchViewModel.abstractSize / 2, y: 0)
                            .frame(maxWidth: .infinity, maxHeight: notchViewModel.deviceNotchRect.height, alignment: Alignment(horizontal: .trailing, vertical: .center))
                    }
                }
            Group {
                if notchViewModel.status == .opened {
                    NotchCompositeView(vm: notchViewModel)
                        .padding(.top, notchViewModel.deviceNotchRect.height - notchViewModel.spacing + 1)
                        .padding(notchViewModel.spacing)
                        .frame(
                            maxWidth: notchViewModel.notchOpenedSize.width, maxHeight: notchViewModel.notchOpenedSize.height
                        )
                } else if notchViewModel.status == .popping {
                    // Position nav just below the physical device notch area
                    Color.clear
                        .frame(
                            width: notchViewModel.notchSize.width,
                            height: notchViewModel.notchSize.height
                        )
                        .overlay(
                            NotchNavView(notchViewModel: notchViewModel)
                                .frame(
                                    maxWidth: notchViewModel.deviceNotchRect.width + notchViewModel.abstractSize + 6,
                                    maxHeight: notchViewModel.deviceNotchRect.height + 36
                                )
                                .padding(.horizontal, notchViewModel.spacing)
                                // Equivalent to previous placement in DynamicView:
                                // top padding ≈ deviceNotchRect.height + 1 so it sits just under the notch
                                .padding(.top, notchViewModel.deviceNotchRect.height + 1),
                            alignment: .top
                        )
                        // Match DynamicView's horizontal offset so edges align
                        .offset(x: notchViewModel.abstractSize / 2, y: 0)
                }
            }
            .zIndex(1)
        }
        .onHover { isHover in
            if !notchModel.isKeyboardTriggered {
                if isHover {
                    reevaluateHover()
                } else {
                    isHovering = false
                    notchViewModel.notchClose()
                }
            }
        }
        // Force re-evaluation when the notch frame changes, even if the mouse hasn't moved
        .onChange(of: notchViewModel.notchSize) { _ in reevaluateHover() }
        .onChange(of: notchViewModel.notchOpenedSize) { _ in reevaluateHover() }
        .onChange(of: notchViewModel.abstractSize) { _ in reevaluateHover() }
        .onChange(of: notchViewModel.status) { _ in reevaluateHover() }
        .onTapGesture {
            notchViewModel.notchOpen(galleryItem: .apps)
        }
    }

    private func reevaluateHover() {
        if notchModel.isKeyboardTriggered { return }
        let mouseLocation: NSPoint = NSEvent.mouseLocation
        let targetRect: CGRect
        switch notchViewModel.status {
        case .opened:
            targetRect = notchViewModel.notchOpenedRect.insetBy(dx: notchViewModel.inset, dy: notchViewModel.inset)
        case .notched, .sliced, .popping:
            targetRect = notchViewModel.notchRect.insetBy(dx: notchViewModel.inset, dy: notchViewModel.inset)
        }
        let currentlyInside = targetRect.contains(mouseLocation)
        if currentlyInside != isHovering {
            isHovering = currentlyInside
            if currentlyInside {
                if notchViewModel.status == .notched || notchViewModel.status == .sliced {
                    notchViewModel.notchPop()
                    notchViewModel.hapticSender.send()
                }
            } else {
                notchViewModel.notchClose()
            }
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
                    notchViewModel.notchOpen(galleryItem: .tray)
                    notchViewModel.hapticSender.send()
                } else if !isTargeted {
                    // Close the notch when the dragged item leaves the area
                    let mouseLocation: NSPoint = NSEvent.mouseLocation
                    if !notchViewModel.notchOpenedRect
                        .insetBy(dx: notchViewModel.inset, dy: notchViewModel.inset)
                        .contains(mouseLocation) {
                        notchViewModel.notchClose()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
