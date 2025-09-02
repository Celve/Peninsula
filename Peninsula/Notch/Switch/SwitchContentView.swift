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
            ForEach(Array(notchModel.stateExpansion.enumerated())[notchModel.globalWindowsBegin..<notchModel.globalWindowsEnd], id: \.offset) { index, element in
                HStack {
                    AppIcon(image: element.1)
                    HStack(spacing: 0) {
                        ForEach(element.2) { matchResult in
                            switch matchResult {
                            case .matched(let matchedString):
                                Text(matchedString).foregroundColor(.blue)
                            case .unmatched(let unmatchedString):
                                Text(unmatchedString).foregroundColor(index == notchModel.globalWindowsPointer ? .black : .white)
                            }
                        }
                    }
                }
                .frame(width: notchViewModel.notchOpenedSize.width - notchViewModel.spacing * 2, height: SwitchContentView.HEIGHT, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(index == notchModel.globalWindowsPointer ? Color.white : Color.clear).frame(maxWidth: .infinity))
                .id(index)
                .onContinuousHover { phase in
                    switch phase {
                    case .active:
                        notchModel.updateExternalPointer(pointer: index)
                    case .ended:
                        notchModel.updateExternalPointer(pointer: nil)
                    }
                }
                .onTapGesture {
                    HotKeyObserver.shared.state = .none
                    notchModel.closeAndFocus()
                }
            }
            .transition(.blurReplace)
        }
        .animation(notchViewModel.normalAnimation, value: notchModel.windowsCounter)
        .animation(notchViewModel.normalAnimation, value: notchModel.state)
        .animation(notchViewModel.normalAnimation, value: notchModel.filterString)
        .transition(.blurReplace)
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct AppIcon: View {
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

