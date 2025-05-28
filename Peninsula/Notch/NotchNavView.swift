import SwiftUI

struct NotchNavButton: View {
    let notchViewModel: NotchViewModel
    let contentType: NotchContentType
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            notchViewModel.notchOpen(contentType: contentType)
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 4).fill(isHovered ? .white : .clear)
                if contentType == .notification {
                    Image(systemName: "app.badge")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(isHovered ? .black : .white)
                        .frame(width: notchViewModel.deviceNotchRect.height * 0.6, height: notchViewModel.deviceNotchRect.height * 0.6)
                } else if contentType == .apps {
                    Image(systemName: "app")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(isHovered ? .black : .white)
                        .frame(width: notchViewModel.deviceNotchRect.height * 0.6, height: notchViewModel.deviceNotchRect.height * 0.6)
                } else if contentType == .timer {
                    Image(systemName: "timer")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(isHovered ? .black : .white)
                        .frame(width: notchViewModel.deviceNotchRect.height * 0.6, height: notchViewModel.deviceNotchRect.height * 0.6)
                } else if contentType == .tray {
                    Image(systemName: "tray")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(isHovered ? .black : .white)
                        .frame(width: notchViewModel.deviceNotchRect.height * 0.6, height: notchViewModel.deviceNotchRect.height * 0.6)
                } else if contentType == .settings {
                    Image(systemName: "gear")   
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(isHovered ? .black : .white)
                        .frame(width: notchViewModel.deviceNotchRect.height * 0.6, height: notchViewModel.deviceNotchRect.height * 0.6)
                }
            }
            .frame(width: notchViewModel.deviceNotchRect.height, height: notchViewModel.deviceNotchRect.height)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered in
            self.isHovered = isHovered
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.white : Color.clear)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}   
    

struct NotchNavView: View {
    @StateObject var notchViewModel: NotchViewModel
    let contentTypes: [NotchContentType] = [.apps, .timer, .tray, .notification, .settings]

    var body: some View {
        HStack {
            ForEach(contentTypes, id: \.self) { contentType in
                NotchNavButton(notchViewModel: notchViewModel, contentType: contentType)
            }
        }
    }
}
