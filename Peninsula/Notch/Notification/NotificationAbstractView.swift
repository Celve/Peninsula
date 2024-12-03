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
    @State var quiver = false

    var body: some View {
        inner.scaleEffect(quiver ? 1.15 : 1)  // Apply a rotation effect for quivering
            .animation(
                quiver
                    ? Animation.easeInOut(duration: 0.1).repeatCount(5, autoreverses: true)
                    : .default,
                value: quiver
            )
            .onAppear {
                quiver = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    quiver = false
                }
            }
    }
}

struct AbstractView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var model: NotificationModel = NotificationModel.shared

    var body: some View {
        ZStack {
            switch model.displayedBadge {
            case .num(let num):
                QuiverView(
                    inner: ScaledPaddingView(
                        inner: Image(systemName: "\(num).square.fill").resizable().aspectRatio(
                            contentMode: .fit
                        ),
                        percentage: 0.1
                    ).padding(vm.deviceNotchRect.height / 8)
                )
            case .icon(let icon):
                QuiverView(
                    inner: Image(nsImage: icon).resizable().aspectRatio(contentMode: .fit).padding(
                        vm.deviceNotchRect.height / 8))
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
        }.animation(.spring, value: model.displayedBadge)
    }
}
