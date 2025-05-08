//
//  TimerMenuView.swift
//  Peninsula
//
//  Created by Celve on 5/6/25.
//

import SwiftUI

struct TimerMenuView: View {
    @StateObject var notchViewModel: NotchViewModel
    @StateObject var timerPickerViewModel = TimerPickerViewModel()
    @State var text: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @StateObject var timerModel = TimerModel.shared

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            TimerPickerView(timerPickerViewModel: timerPickerViewModel, timerModel: timerModel, notchViewModel: notchViewModel)
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(timerModel.viewModels, id: \.self) { timerViewModel in
                            TimerView(timerViewModel: timerViewModel)
                        }
                        .animation(.easeInOut(duration: 0.2), value: timerModel.viewModels)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .animation(.easeInOut(duration: 0.2), value: timerModel.viewModels)
                Spacer()
                Text(timerModel.description)
                    .lineLimit(1)
                    .opacity(timerModel.description == "None" ? 0 : 1)
                    .transition(.opacity)
                    .animation(notchViewModel.normalAnimation, value: timerModel.description)
                    .contentTransition(.numericText())
            }
        }
        .padding(0)
        .onAppear { 
            timerModel.clearExpiredTimers()
        }
    }
}

