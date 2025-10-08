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
            // Liquid glass hover treatment for nav buttons
            .background(
                Group {
                    if isHovered {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.regularMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.98), Color.white.opacity(0.92)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.95), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 2)
                    } else {
                        Color.clear
                    }
                }
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered in
            self.isHovered = isHovered
        }
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
                    .id(contentType)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .opacity.combined(with: .scale(scale: 0.9))
                        )
                    )
            }
        }
        // Animate button insert/remove when the nav appears/disappears
        .animation(notchViewModel.normalAnimation, value: notchViewModel.status)
    }
}
