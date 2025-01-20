//
//  SwitchContentView.swift
//  Island
//
//  Created by Celve on 9/29/24.
//

import Foundation
import SwiftUI

struct SwitchContentView: View {
    @StateObject var windows = Windows.shared
    @StateObject var apps = Apps.shared
    @StateObject var notchViewModel: NotchViewModel
    @StateObject var notchModel: NotchModel = NotchModel.shared
    static let HEIGHT: CGFloat = 50
    static let COUNT: Int = 8
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(notchModel.stateExpansion.enumerated())[notchModel.globalWindowsBegin..<notchModel.globalWindowsEnd], id: \.offset) { index, window in
                HStack {
                    AppIcon(name: window.getTitle() ?? "", image: (window.getIcon() ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)!))
                    Text(window.getTitle() ?? "").foregroundStyle(index == notchModel.globalWindowsPointer ? .black : .white).lineLimit(1)
                }
                .frame(width: notchViewModel.notchOpenedSize.width - notchViewModel.spacing * 2, height: SwitchContentView.HEIGHT, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(index == notchModel.globalWindowsPointer ? Color.white : Color.clear).frame(maxWidth: .infinity))
                .id(index)
                .onHover { hover in
                    if hover {
                        notchModel.updateExternalPointer(pointer: index)
                    } else {
                        notchModel.updateExternalPointer(pointer: nil)
                    }
                }
                .onTapGesture {
                    HotKeyObserver.shared.state = .none
                    notchModel.closeAndFocus()
                }
            }
            .animation(notchViewModel.normalAnimation, value: notchModel.windowsCounter)
            .animation(notchViewModel.normalAnimation, value: notchModel.state)
            .transition(.blurReplace)
        }
        .animation(notchViewModel.normalAnimation, value: notchModel.windowsCounter)
        .transition(.blurReplace)
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct AppIcon: View {
    let name: String
    let image: NSImage

    var body: some View {
        ZStack {
            Image(nsImage: image)
                .resizable()
                .contentShape(Rectangle())
                .aspectRatio(contentMode: .fit)
        }
    }
}

