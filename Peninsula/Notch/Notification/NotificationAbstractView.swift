//
//  AbstractView.swift
//  Island
//
//  Created by Celve on 9/20/24.
//

import Foundation
import SwiftUI

struct QuiverView<Inner: View>: View {
    let inner: Inner
    let tapGesture: () -> Void
    @State var quiver = false
    @State var hover = false

    var body: some View {
        inner.scaleEffect(quiver ? 1.15 : 1)  // Apply a rotation effect for quivering
            .animation(
                quiver
                    ? Animation.easeInOut(duration: 0.1).repeatCount(5, autoreverses: true)
                    : .default,
                value: quiver
            )
            .scaleEffect(hover ? 1.15 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: hover)
            .onAppear {
                quiver = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    quiver = false
                }
            }
            .onHover { hover in
                self.hover = hover
            }
            .onTapGesture(perform: tapGesture)
    }
}

struct NotificationAbstractView: View {
    @StateObject var notchViewModel: NotchViewModel
    @StateObject var notifModel: NotificationModel = NotificationModel.shared

    var body: some View {
        ZStack {
            switch notchViewModel.status {
            case .sliced:
                EmptyView()
            case .notched, .popping:
                HStack {
                    ForEach(Array(notifModel.names), id: \.self) { name in
                        if let item = notifModel.temporaryItems[name] {
                            QuiverView(
                                inner: AnyView(item.icon),
                                tapGesture: {
                                    item.action(notchViewModel)
                                }
                            ).padding(notchViewModel.deviceNotchRect.height / 12)
                        } else if let item = notifModel.alwaysItems[name] {
                            QuiverView(
                                inner: AnyView(item.icon),
                                tapGesture: {
                                    item.action(notchViewModel)
                                }
                            ).padding(notchViewModel.deviceNotchRect.height / 12)
                        }
                    }
                }
            case .opened:
                EmptyView()
            }
        }
            .animation(.spring, value: notifModel.names)
            .animation(.spring, value: notifModel.temporaryItems.map { $0.value.id })
            .animation(.spring, value: notifModel.alwaysItems.map { $0.value.id })
    }
}
