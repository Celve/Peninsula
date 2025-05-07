import SwiftUI

class TimePickerViewModel: ObservableObject {
    @Published var position: Int? = nil
    let total: Int
    let bufferTotal: Int
    let initPos: Int
    let paddingCount: Int = 2

    var safePosition: Int {
        if let position = position {
            position
        } else {
            0
        }
    }

    var trueValue: Int { 
        if let position = position {
            max(position - paddingCount, 0)
        } else {
            0
        }
    }

    init(total: Int, bufferTotal: Int, initPos: Int) {
        self.total = total
        self.bufferTotal = bufferTotal
        self.initPos = initPos
    }

    func setPosition(position: Int) {
        self.position = position + paddingCount
    }
}

struct TimePickerView: View {
    @StateObject var viewModel: TimePickerViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
                ForEach(0..<(viewModel.bufferTotal + viewModel.paddingCount * 2), id: \.self) { index in
                    if index < viewModel.paddingCount || index >= viewModel.bufferTotal + viewModel.paddingCount {
                        // Padding: invisible/transparent
                        Text(" ")
                            .frame(height: 14)
                            .opacity(0)
                    } else {
                        let value = index - viewModel.paddingCount
                        Text("\(value % viewModel.total)")
                            .frame(height: 14)
                            .id(index)
                            .font(.system(size: abs(viewModel.safePosition - index) <= 2 ? 22 - Double(abs(viewModel.safePosition - index)) * 4 : 14))
                            .fontWeight(viewModel.safePosition == index ? .bold : .regular)
                            .scaleEffect(abs(viewModel.safePosition - index) <= 2 ? 1.2 - Double(abs(viewModel.safePosition - index)) * 0.1 : 0.8)
                            .opacity(abs(viewModel.safePosition - index) <= 2 ? 1.0 - Double(abs(viewModel.safePosition - index)) * 0.2 : 0.4)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.safePosition)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $viewModel.position, anchor: .center)
        .animation(.spring(duration: 0.8), value: viewModel.position)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .frame(width: 35)
        .onAppear {
            viewModel.position = viewModel.initPos + viewModel.paddingCount
        }
    }
}

class TimerPickerViewModel: ObservableObject {
    @Published var hoursViewModel = TimePickerViewModel(total: 99, bufferTotal: 99, initPos: 0) 
    @Published var minutesViewModel = TimePickerViewModel(total: 60, bufferTotal: 60, initPos: 0) 
    @Published var secondsViewModel = TimePickerViewModel(total: 60, bufferTotal: 60, initPos: 0) 
}

struct TimerPickerView: View {
    @StateObject var timerPickerViewModel: TimerPickerViewModel
    @StateObject var timerModel: TimerModel
    @StateObject var notchViewModel: NotchViewModel
    @FocusState private var isTextFieldFocused: Bool
    @State var text: String = ""

    var body: some View {
        VStack { 
            HStack {
                TimePickerView(viewModel: timerPickerViewModel.hoursViewModel)
                Divider()
                    .frame(height: 100)
                    .background(.white.opacity(0.4))
                TimePickerView(viewModel: timerPickerViewModel.minutesViewModel)
                Divider()
                    .frame(height: 100)
                    .background(.white.opacity(0.4))
                TimePickerView(viewModel: timerPickerViewModel.secondsViewModel)
            }
            TextField("", text: $text)
                .focused($isTextFieldFocused)
                .textFieldStyle(.plain)
                .lineLimit(1)
                .opacity(text.isEmpty ? 0 : 1)
                .transition(.opacity)
                .animation(notchViewModel.normalAnimation, value: text)
                .multilineTextAlignment(.center)
                .onSubmit {
                    if match(text: text, pattern: #"(\d+)h"#) == nil { 
                        timerPickerViewModel.hoursViewModel.setPosition(position: 0)
                    }
                    if match(text: text, pattern: #"(\d+)m"#) == nil { 
                        timerPickerViewModel.minutesViewModel.setPosition(position: 0)
                    }
                    if match(text: text, pattern: #"(\d+)s"#) == nil { 
                        timerPickerViewModel.secondsViewModel.setPosition(position: 0)
                    }
                    timerModel.add(time: timerPickerViewModel.hoursViewModel.trueValue * 3600 + timerPickerViewModel.minutesViewModel.trueValue * 60 + timerPickerViewModel.secondsViewModel.trueValue)
                    text = "" // Clear the text field after submission
                }
                .onChange(of: text) { newValue in
                    if let hourMatch = match(text: newValue, pattern: #"(\d+)h"#) {
                        timerPickerViewModel.hoursViewModel.setPosition(position: hourMatch)
                    }
                    if let minuteMatch = match(text: newValue, pattern: #"(\d+)m"#) {
                        timerPickerViewModel.minutesViewModel.setPosition(position: minuteMatch)
                    }
                    if let secondMatch = match(text: newValue, pattern: #"(\d+)s"#) {
                        timerPickerViewModel.secondsViewModel.setPosition(position: secondMatch)
                    }
                }
                .onAppear {
                    isTextFieldFocused = true
                }
                .frame(width: 100)
        }.padding(.horizontal, 0)
    }

    func match(text: String, pattern: String) -> Int? {
        if let range = text.range(of: pattern, options: .regularExpression) {
            return Int(text[range].dropLast())
        }
        return nil
    }
}

