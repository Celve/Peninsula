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
    @StateObject var nvm: NotchViewModel
    @StateObject var svm = SwitchContentViewModel()
    static let HEIGHT: CGFloat = 50
    static let COUNT: Int = 8
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(windows.inner.enumerated())[nvm.windowsBegin..<nvm.windowsEnd], id: \.offset) { index, window in
                HStack {
                    AppIcon(name: window.title, image: (window.application.icon ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)!), svm: svm)
                    Text(window.title).foregroundStyle(index == nvm.windowsPointer ? .black : .white).lineLimit(1)
                }
                .frame(width: nvm.notchOpenedSize.width - nvm.spacing * 2, height: SwitchContentView.HEIGHT, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(index == nvm.windowsPointer ? Color.white : Color.clear).frame(maxWidth: .infinity))
                .id(index)
            }
            .animation(nvm.normalAnimation, value: nvm.windowsCounter)
            .transition(.blurReplace)
        }
        .animation(nvm.normalAnimation, value: nvm.windowsCounter)
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

