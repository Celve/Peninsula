//
//  NotificationContentView.swift
//  Island
//
//  Created by Celve on 9/20/24.
//

import ColorfulX
import SwiftUI

struct NotificationContentView: View {
    @StateObject var nvm: NotchViewModel
    @StateObject var nm = NotificationModel.shared
    @State var isAnimating = false

    var body: some View {
        HStack(alignment: .top, spacing: nvm.spacing) {
            ForEach(Array(nm.items.keys), id: \.self) { key in
                AppIcon(bundleId: key, image: nm.items[key]!.icon, vm: nvm)
            }
        }.animation(nvm.normalAnimation, value: nm.items)
    }
}

private struct AppIcon: View {
    let bundleId: String
    let image: NSImage
    @ObservedObject var nm = NotificationModel.shared
    @StateObject var vm: NotchViewModel

    @State var hover: Bool = false
    @State var quiver: Bool = false
    @State var iconWidth: CGFloat = 0
    @State var iconHeight: CGFloat = 0

    var body: some View {
        ZStack {
            Image(nsImage: image)
                .resizable()
                .contentShape(Rectangle())
                .aspectRatio(contentMode: .fit)
                .scaleEffect(hover ? 1.15 : 1)
                .animation(.spring(), value: hover)
                .rotationEffect(.degrees(quiver ? 5 : 0))  // Apply a rotation effect for quivering
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                iconWidth = geometry.frame(in: .local).width
                                iconHeight = geometry.frame(in: .local).height
                            }
                            .onChange(of: geometry.frame(in: .local)) {
                                iconWidth = geometry.frame(in: .local).width
                                iconHeight = geometry.frame(in: .local).height
                            }
                    }
                )
                .overlay(
                    ZStack {
                        if let badge = nm.items.filter({ $0.value.bundleId == bundleId }).first?.value.badge
                        {
                            switch badge {
                            case .count(let count):
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: iconWidth * 0.25, height: iconHeight * 0.25)
                                    Text(String(count))
                                        .font(.system(size: iconHeight * 0.15, design: .rounded))
                                        .foregroundColor(.white)
                                }.offset(x: hover ? iconWidth * 0.05 : 0, y: hover ? -iconHeight * 0.05 : 0)
                                .animation(.spring, value: hover)
                            case .text(let text):
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: iconWidth * 0.25, height: iconHeight * 0.25)
                                    Text(".")
                                        .font(.system(size: iconHeight * 0.15, design: .rounded))
                                        .foregroundColor(.white)
                                }.offset(x: hover ? iconWidth * 0.05 : 0, y: hover ? -iconHeight * 0.05 : 0)
                                .animation(.spring, value: hover)
                            case .null:
                                EmptyView()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                )
                .animation(
                    quiver
                        ? Animation.easeInOut(duration: 0.1).repeatForever(autoreverses: true)
                        : .default,
                    value: quiver
                )
                .onHover { hover in
                    self.hover = hover
                }
                .onTapGesture {
                    if vm.mode == .delete {
                        nm.unobserve(bundleId: bundleId)
                    } else {
                        vm.notchClose()
                        nm.open(bundleId: bundleId)
                    }
                }
                .onChange(of: vm.mode) { newMode in
                    if newMode == .delete {
                        quiver = true
                    } else {
                        quiver = false
                    }
                }
        }
        .animation(vm.normalAnimation, value: vm.contentType)
        .animation(vm.status == .opened ? vm.innerOnAnimation : vm.innerOffAnimation, value: vm.status)
        
    }
}

private struct ColorButton: View {
    let color: [Color]
    let image: Image
    let title: LocalizedStringKey

    @State var hover: Bool = false

    var body: some View {
        Color.white
            .opacity(0.1)
            .overlay(
                ColorfulView(
                    color: .constant(color),
                    speed: .constant(0)
                )
                .mask {
                    VStack(spacing: 8) {
                        Text("888888")
                            .hidden()
                            .overlay {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        Text(title)
                    }
                    .font(.system(.headline, design: .rounded))
                }
                .contentShape(Rectangle())
                .scaleEffect(hover ? 1.15 : 1)
                .animation(.spring, value: hover)
                .onHover { hover = $0 }
            )
            .aspectRatio(1, contentMode: .fit)
            .contentShape(Rectangle())
    }
}
