//
//  SwitchContentView.swift
//  Island
//
//  Created by Celve on 9/22/24.
//

import SwiftUI

class AppsViewModel: ObservableObject {
    @Published var title: String = "None"
}

struct AppsContentView: View {
    let vm: NotchViewModel
    @StateObject var windows = Windows.shared
    @StateObject var svm = AppsViewModel()
    
    var body: some View {
        VStack {
            HStack {
                ForEach(Array(windows.inner.filter({ if let frame = try? $0.axWindow.frame() { vm.cgScreenRect.intersects(frame) } else { false } }).enumerated()), id: \.offset) { index, window in
                    AppIcon(name: window.title, image: (window.application.icon ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)!), vm: vm, svm: svm)
                        .onTapGesture {
                            window.focus()
                            vm.notchClose()
                        }
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            Spacer()
            Text(svm.title)
                .lineLimit(1)
                .opacity(svm.title == "None" ? 0 : 1)
                .transition(.opacity)
                .animation(vm.normalAnimation, value: svm.title)
                .contentTransition(.numericText())
        }
    }
}


private struct AppIcon: View {
    let name: String
    let image: NSImage
    @StateObject var vm: NotchViewModel
    @State var hover: Bool = false
    @StateObject var svm: AppsViewModel

    var body: some View {
        ZStack {
            Image(nsImage: image)
                .resizable()
                .contentShape(Rectangle())
                .aspectRatio(contentMode: .fit)
                .scaleEffect(hover ? 1.15 : 1)
                .animation(.spring(), value: hover)
                .onHover { hover in
                    self.hover = hover
                    svm.title = hover ? name : "None"
                }
        }
    }
}

