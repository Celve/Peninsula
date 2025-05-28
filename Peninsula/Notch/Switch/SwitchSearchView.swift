//
//  SwitchSearchView.swift
//  Peninsula
//
//  Created by Celve on 5/28/25.
//

import SwiftUI

struct SwitchSearchView: View {
    static let LINEHEIGHT: CGFloat = 16
    @StateObject var notchViewModel: NotchViewModel
    @StateObject var notchModel: NotchModel = NotchModel.shared
    @FocusState var isFocused: Bool

    var body: some View {
        VStack {
            SwitchContentView(notchViewModel: notchViewModel)
            TextField("Search", text: $notchModel.filterString)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .frame(height: SwitchSearchView.LINEHEIGHT)
                .padding(.horizontal, 8)
                .onAppear {
                    isFocused = true
                }
        }
        .onKeyPress { press in
            if press.key == KeyEquivalent(Character("p")) && press.modifiers.contains(.control) {
                DispatchQueue.main.async {
                    notchModel.decrementPointer()
                }
                return .handled
            }
            if press.key == KeyEquivalent(Character("n")) && press.modifiers.contains(.control) {
                DispatchQueue.main.async {
                    notchModel.incrementPointer()
                }
                return .handled
            }
            
            switch press.key {
            case .upArrow:
                DispatchQueue.main.async {
                    notchModel.decrementPointer()
                }
                return .handled
            case .downArrow:
                DispatchQueue.main.async {
                    notchModel.incrementPointer()
                }
                return .handled
            case .return:
                DispatchQueue.main.async {
                    notchModel.closeAndFocus()
                }
                return .handled
            case .escape:
                DispatchQueue.main.async {
                    notchModel.notchClose()
                }
                return .handled
            default:
                return .ignored
            }
        }
    }
}
