//
//  NotchStatusView.swift
//  Island
//
//  Created by Celve on 9/20/24.
//

import ColorfulX
import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum SwipeDirection {
    case up
    case down
    case left
    case right
}

struct NotchDynamicView: View {
    @StateObject var notchViewModel: NotchViewModel
    @StateObject var notchModel = NotchModel.shared
    @StateObject var sysNotifModel = SystemNotificationModel.shared
    @StateObject var notifModel = NotificationModel.shared
    @ObservedObject var windows = Windows.shared

    var body: some View {
        Rectangle()
            .foregroundStyle(.black)
            .mask(notchBackgroundMaskGroup)
            .frame(
                width: notchViewModel.notchSize.width + notchViewModel.notchCornerRadius * 2,
                height: notchViewModel.notchSize.height
            )
            .overlay(
                Group {
                    if notchViewModel.status != .opened {
                        NotificationAbstractView(notchViewModel: notchViewModel)
                            .frame(maxWidth: .infinity, maxHeight: notchViewModel.deviceNotchRect.height, alignment: Alignment(horizontal: .trailing, vertical: .center))
                            .offset(x: -notchViewModel.spacing)
                            .transition(
                                .blurReplace
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            )
            .overlay(
                Group {
                    if notchViewModel.status == .popping {
                        NotchNavView(notchViewModel: notchViewModel)
                        .padding(.top, notchViewModel.deviceNotchRect.height - notchViewModel.spacing + 1)
                        .padding(notchViewModel.spacing)
                        .frame(
                            maxWidth: notchViewModel.deviceNotchRect.width + notchViewModel.abstractSize + 6, maxHeight: notchViewModel.deviceNotchRect.height + 36
                        )
                        .zIndex(1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            )
            .overlay(
                Group {
                    if notchViewModel.status == .opened {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .frame(
                                width: notchViewModel.notchOpenedRect.width,
                                height: notchViewModel.deviceNotchRect.height
                            )
                            .onTapGesture {
                                notchViewModel.contentType = notchViewModel.contentType.next(invisibles: notchModel.invisibleContentTypes)
                            }
                    }
                },
                alignment: .top
            )
            .shadow(
                color: .black.opacity(([.opened, .popping].contains(notchViewModel.status)) ? 1 : 0),
                radius: 16
            )
            .offset(x: notchViewModel.abstractSize / 2, y: 0)
            .animation(
                notchViewModel.status == .opened
                ? notchViewModel.outerOnAnimation
                : notchViewModel.status == .notched ? notchViewModel.outerOffAnimation : notchViewModel.normalAnimation,
                value: notchViewModel.status
            )
            .animation(notchViewModel.outerOnAnimation, value: notchViewModel.contentType)
            .animation(notchViewModel.normalAnimation, value: notchViewModel.abstractSize)
            .animation(notchViewModel.outerOnAnimation, value: notchViewModel.notchOpenedSize)
            // .onAppear(perform:{
            //     var lastEvent: (SwipeDirection, TimeInterval)? = nil
            //     let threshold = 3.0
            //     NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) {event in
            //         if notchViewModel.status == .opened {
            //             let direction: SwipeDirection? = if event.deltaX > threshold {
            //                 .right
            //             } else if event.deltaX < -threshold {
            //                 .left
            //             } else if event.deltaY > threshold {
            //                 .down
            //             } else if event.deltaY < -threshold {
            //                 .up
            //             } else { 
            //                 nil
            //             }
                        
            //             if direction != nil && (lastEvent == nil || event.timestamp - lastEvent!.1 > 0.3 || direction != lastEvent!.0) {
            //                 if direction == .left {
            //                     notchViewModel.contentType = notchViewModel.contentType.next(invisibles: notchModel.invisibleContentTypes)
            //                 } else if direction == .right {
            //                     notchViewModel.contentType = notchViewModel.contentType.previous(invisibles: notchModel.invisibleContentTypes)
            //                 }
            //                 lastEvent = (direction!, event.timestamp)
            //             }
            //         }
                    
            //         return event
            //     }
            // })
    }

    var notchBackgroundMaskGroup: some View {
        Rectangle()
            .foregroundStyle(.black)
            .frame(
                width: notchViewModel.notchSize.width,
                height: notchViewModel.notchSize.height
            )
            .clipShape(
                .rect(
                    bottomLeadingRadius: notchViewModel.notchCornerRadius,
                    bottomTrailingRadius: notchViewModel.notchCornerRadius
                )
            )
            .overlay {
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .frame(width: notchViewModel.notchCornerRadius, height: notchViewModel.notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topTrailingRadius: notchViewModel.notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: notchViewModel.notchCornerRadius + notchViewModel.spacing,
                            height: notchViewModel.notchCornerRadius + notchViewModel.spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .offset(x: -notchViewModel.notchCornerRadius - notchViewModel.spacing + 0.5, y: -0.5)
            }
            .overlay {
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .frame(width: notchViewModel.notchCornerRadius, height: notchViewModel.notchCornerRadius)
                        .foregroundStyle(.black)
                    Rectangle()
                        .clipShape(.rect(topLeadingRadius: notchViewModel.notchCornerRadius))
                        .foregroundStyle(.white)
                        .frame(
                            width: notchViewModel.notchCornerRadius + notchViewModel.spacing,
                            height: notchViewModel.notchCornerRadius + notchViewModel.spacing
                        )
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: notchViewModel.notchCornerRadius + notchViewModel.spacing - 0.5, y: -0.5)
            }
    }
}
