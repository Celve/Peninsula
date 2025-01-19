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

struct AbstractView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var model: NotificationModel = NotificationModel.shared

    var body: some View {
        ZStack {
            switch vm.status {
            case .sliced:
                switch model.displayedBadge {
                case .num, .time:
                    QuiverView(inner: RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: vm.abstractSize - 4 * vm.deviceNotchRect.height / 8, height: 2), tapGesture: {
                            vm.notchOpen(contentType: .notification)
                        })
                case .icon(_, let color):
                    QuiverView(inner: RoundedRectangle(cornerRadius: 4)
                        .fill(Color(color))
                        .frame(width: vm.abstractSize - 4 * vm.deviceNotchRect.height / 8, height: 2), tapGesture: {
                            if model.displayedName != "" {
                                model.open(bundleId: model.displayedName)
                            } else {
                                vm.notchOpen(contentType: .notification)
                            }
                        })
                case .none:
                    EmptyView()
                }
            case .notched, .popping:
                switch model.displayedBadge {
                case .num(let num):
                    QuiverView(
                        inner: ScaledPaddingView(
                            inner: Image(systemName: "\(num).square.fill").resizable().aspectRatio(
                                contentMode: .fit
                            ),
                            percentage: 0.1
                        ).padding(vm.deviceNotchRect.height / 8),
                        tapGesture: {
                            vm.notchOpen(contentType: .notification)
                        }
                    )
                case .icon(let icon, _):
                    QuiverView(
                        inner: Image(nsImage: icon).resizable().aspectRatio(contentMode: .fit).padding(
                            vm.deviceNotchRect.height / 8), tapGesture: {
                                if model.displayedName != "" {
                                    model.open(bundleId: model.displayedName)
                                } else {
                                    vm.notchOpen(contentType: .notification)
                                }
                            })
                case .time(let hour, let min):
                    HStack(spacing: vm.deviceNotchRect.height / 8) {
                        ScaledPaddingView(
                            inner: Image(systemName: "\(hour / 10).square.fill").resizable().aspectRatio(
                                contentMode: .fit
                            ),
                            percentage: 0.1
                        )
                        ScaledPaddingView(
                            inner: Image(systemName: "\(hour % 10).square.fill").resizable().aspectRatio(
                                contentMode: .fit
                            ),
                            percentage: 0.1
                        )
                        ScaledPaddingView(
                            inner: Image(systemName: "\(min / 10).square").resizable().aspectRatio(
                                contentMode: .fit
                            ),
                            percentage: 0.1
                        )
                        ScaledPaddingView(
                            inner: Image(systemName: "\(min % 10).square").resizable().aspectRatio(
                                contentMode: .fit
                            ),
                            percentage: 0.1
                        )
                    }.padding(vm.deviceNotchRect.height / 8)
                case .none:
                    EmptyView()
                }
            case .opened:
                EmptyView()
            }
        }.animation(.spring, value: model.displayedBadge)
    }
}
