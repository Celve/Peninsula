//
//  NotificationContentView.swift
//  Island
//
//  Created by Celve on 9/20/24.
//

import ColorfulX
import SwiftUI

struct NotificationContentView: View {
    @StateObject var notchViewModel: NotchViewModel
    @StateObject var dockModel = DockModel.shared
    @State var isAnimating = false

    var body: some View {
        HStack(alignment: .top, spacing: notchViewModel.spacing) {
            ForEach(Array(dockModel.items.keys), id: \.self) { key in
                if let item = dockModel.items[key] {
                    AppIcon(bundleId: key, image: AnyView(item.icon), vm: notchViewModel)
                }
            }
        }.animation(notchViewModel.normalAnimation, value: dockModel.items)
    }
}