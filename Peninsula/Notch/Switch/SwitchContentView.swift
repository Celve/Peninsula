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
    
    // Precompute the visible slice to avoid recomputing the whole expansion
    var items: [(Int, (any Switchable, NSImage, [MatchableString.MatchResult]))] {
        SwitchManager.shared.itemsSlice(
            state: notchModel.state,
            contentType: notchModel.contentType,
            filterString: notchModel.filterString,
            range: notchModel.pageStart..<notchModel.pageEnd
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(items, id: \.0) { index, element in
                HStack {
                    AppIcon(image: element.1)
                    HStack(spacing: 0) {
                        ForEach(element.2) { matchResult in
                            switch matchResult {
                            case .matched(let matchedString):
                            // Highlight matched fragments using accent color for better contrast
                            Text(matchedString)
                                .foregroundColor(.accentColor)
                            case .unmatched(let unmatchedString):
                            // Ensure selected row text stays readable on white glass
                            Text(unmatchedString)
                                .foregroundColor(index == notchModel.activeIndex ? .black : .primary)
                            }
                        }
                    }
                }
                .frame(
                    width: notchViewModel.notchOpenedSize.width - notchViewModel.spacing * 2,
                    height: SwitchContentView.HEIGHT,
                    alignment: .leading
                )
                // Tahoe liquid glass styling only when selected
                .background(
                    Group {
                        if index == notchModel.activeIndex {
                            // Keep blur via material, push a bright white tint + glossy gradient
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.regularMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.98),
                                                    Color.white.opacity(0.92)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    // Brighter selection ring for clarity
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.95), lineWidth: 1.5)
                                )
                                .shadow(color: .black.opacity(0.28), radius: 12, x: 0, y: 3)
                        } else {
                            Color.clear
                        }
                    }
                )
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
        .animation(notchViewModel.normalAnimation, value: notchModel.selectionCounter)
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
