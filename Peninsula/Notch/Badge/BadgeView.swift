import SwiftUI

struct BadgeView: View {
    @StateObject var notchViewModel: NotchViewModel
    @StateObject var badgeModel: BadgeModel = BadgeModel.shared

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(badgeModel.temporaryItems), id: \.id) { item in
                AnyView(item.view(notchViewModel))
                    .frame(width: item.size.width, height: item.size.height)
                    .padding(8)
            }
        }
        .animation(.spring, value: badgeModel.temporaryItems.map { $0.id })
        .animation(.spring, value: badgeModel.alwaysItems.map { $0.id })
    }
}
