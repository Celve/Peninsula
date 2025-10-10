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
    var notchViewModel: NotchViewModel
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
                if let window = NSApp.windows.first(where: { $0.windowNumber == notchViewModel.windowId }) {
                    window.makeKey()
                }
            }
            .onTapGesture(perform: tapGesture)
    }
}

struct LiveView: View {
    @StateObject var notchViewModel: NotchViewModel
    @StateObject var liveModel: LiveModel = LiveModel.shared

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(liveModel.names), id: \.self) { name in
                if let item = liveModel.temporaryItems[name] {
                    QuiverView(
                        inner: AnyView(item.icon(notchViewModel)),
                        tapGesture: {
                            item.action(notchViewModel)
                        },
                        notchViewModel: notchViewModel
                    ).padding(notchViewModel.deviceNotchRect.height / 12)
                } else if let item = liveModel.alwaysItems[name] {
                    QuiverView(
                        inner: AnyView(item.icon(notchViewModel)),
                        tapGesture: {
                            item.action(notchViewModel)
                        },
                        notchViewModel: notchViewModel
                    ).padding(notchViewModel.deviceNotchRect.height / 12)
                }
            }
        }
        .animation(.spring, value: liveModel.names)
        .animation(.spring, value: liveModel.temporaryItems.map { $0.value.id })
        .animation(.spring, value: liveModel.alwaysItems.map { $0.value.id })
    }
}
