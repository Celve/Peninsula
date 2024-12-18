//
//  SwitchContentView.swift
//  Island
//
//  Created by Celve on 9/29/24.
//

import Foundation
import SwiftUI

class SwitchContentViewModel: ObservableObject {
}

struct SwitchContentView: View {
    @StateObject var windows = Windows.shared
    @StateObject var notchViewModel: NotchViewModel
    @StateObject var notchModel: NotchModel = NotchModel.shared
    @StateObject var svm = SwitchContentViewModel()
    static let HEIGHT: CGFloat = 50
    static let COUNT: Int = 8
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(windows.inner.enumerated())[notchModel.globalWindowsBegin..<notchModel.globalWindowsEnd], id: \.offset) { index, window in
                HStack {
                    AppIcon(name: window.title, image: (window.application.icon ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)!), svm: svm)
                    Text(window.title).foregroundStyle(index == notchModel.globalWindowsPointer ? .black : .white).lineLimit(1)
                }
                .frame(width: notchViewModel.notchOpenedSize.width - notchViewModel.spacing * 2, height: SwitchContentView.HEIGHT, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(index == notchModel.globalWindowsPointer ? Color.white : Color.clear).frame(maxWidth: .infinity))
                .id(index)
                .onHover { hover in
                    if hover {
                        NotchModel.shared.updatePointer(pointer: index)
                    }
                }
            }
            .animation(notchViewModel.normalAnimation, value: notchModel.windowsCounter)
            .transition(.blurReplace)
        }
        .animation(notchViewModel.normalAnimation, value: notchModel.windowsCounter)
        .transition(.blurReplace)
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AppIcon: View {
    let name: String
    let image: NSImage
    @StateObject var svm: SwitchContentViewModel

    var body: some View {
        ZStack {
            Image(nsImage: image)
                .resizable()
                .contentShape(Rectangle())
                .aspectRatio(contentMode: .fit)
        }
    }
}

