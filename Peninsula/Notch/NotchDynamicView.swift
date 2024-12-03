//
//  NotchStatusView.swift
//  Island
//
//  Created by Celve on 9/20/24.
//

import Foundation
import ColorfulX
import SwiftUI
import UniformTypeIdentifiers

struct NotchDynamicView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var nm = NotificationModel.shared
    
    var body: some View {
        Rectangle()
            .foregroundStyle(.black)
            .mask(notchBackgroundMaskGroup)
            .frame(
                width: vm.notchSize.width + vm.notchCornerRadius * 2,
                height: vm.notchSize.height
            )
            .overlay(
                Group {
                    if vm.status != .opened {
                        AbstractView(vm: vm)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                            .offset(x: -vm.spacing)
                            .transition(
                                .blurReplace
                            )
                    }
                }
            )
            .shadow(
                color: .black.opacity(([.opened, .popping].contains(vm.status)) ? 1 : 0),
                radius: 16
            )
            .offset(x: vm.abstractSize / 2, y: 0)
            .animation(vm.status == .opened ? vm.outerOnAnimation : vm.status == .closed ? vm.outerOffAnimation : vm.normalAnimation, value: vm.status)
            .animation(vm.outerOnAnimation, value: vm.contentType)
            .animation(vm.normalAnimation, value: vm.abstractSize)
    }
    
    var notchBackgroundMaskGroup: some View {
        Rectangle()
            .foregroundStyle(.black)
            .frame(
                width: vm.notchSize.width,
                height: vm.notchSize.height
            )
            .clipShape(.rect(
                bottomLeadingRadius: vm.notchCornerRadius,
                bottomTrailingRadius: vm.notchCornerRadius
            ))
            .overlay {
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .frame(width: vm.notchCornerRadius, height: vm.notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topTrailingRadius: vm.notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: vm.notchCornerRadius + vm.spacing,
                            height: vm.notchCornerRadius + vm.spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -vm.notchCornerRadius - vm.spacing + 0.5, y: -0.5)
            }
            .overlay {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .frame(width: vm.notchCornerRadius, height: vm.notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topLeadingRadius: vm.notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: vm.notchCornerRadius + vm.spacing,
                            height: vm.notchCornerRadius + vm.spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: vm.notchCornerRadius + vm.spacing - 0.5, y: -0.5)
            }
    }
}

