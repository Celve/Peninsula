//
//  TimerView.swift
//  Peninsula
//
//  Created by Celve on 5/6/25.
//

import SwiftUI

struct PressDownAnimationStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct TimerView: View {
    @StateObject var timerViewModel: TimerViewModel
    let timerColor: Color = .white.opacity(0.8)
    @State private var isHovering: Bool = false

    let lineWidth: CGFloat = 5
    let fontSize: CGFloat = 18
    let circleWidth: CGFloat = 100
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: lineWidth)
                    .foregroundStyle(timerColor.opacity(0.4))
                    .padding(lineWidth)
                    .frame(width: circleWidth, height: circleWidth)
                Circle()
                    .trim(from: 0.0, to: min(1-timerViewModel.progress, 1.0))
                    .stroke(timerColor.gradient, style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        lineJoin: .miter))
                    .rotationEffect(.degrees(-90))
                    .shadow(radius: 2)
                    .padding(lineWidth)
                    .frame(width: circleWidth, height: circleWidth)
                VStack(spacing: 0) { 
                    Button(action: {
                        if timerViewModel.isRunning {
                            timerViewModel.stop()
                        } else {
                            timerViewModel.start()
                        }
                    }) {
                        Text(displayTime(timerViewModel.remainingTime))
                            .monospacedDigit()
                            .font(.system(size: fontSize, weight: .medium))
                            .foregroundStyle(.white)
                            .contentShape(Rectangle())
                            .bold()
                            .contentTransition(.numericText())
                    }
                    .onHover { hovering in
                        isHovering = hovering
                    }
                    .scaleEffect(isHovering ? 1.1 : 1)
                    .animation(.easeInOut(duration: 0.2), value: isHovering)
                    .buttonStyle(PressDownAnimationStyle())
                    .buttonStyle(.plain)

                    HStack {
                        Button(action: {
                            timerViewModel.reset()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: fontSize / 2))
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                )
                        }
                        .disabled(timerViewModel.resetButtonDisabled)
                        .opacity(timerViewModel.resetButtonDisabled ? 0.5 : 1)
                        .animation(.easeInOut(duration: 0.2), value: timerViewModel.resetButtonDisabled)
                        .buttonStyle(PressDownAnimationStyle())
                        Button(action: {
                            TimerModel.shared.remove(id: timerViewModel.id)
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: fontSize / 2))
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                )
                        }
                        .buttonStyle(PressDownAnimationStyle())
                    }
                }
                .frame(width: circleWidth, height: circleWidth)
            }
            .animation(.linear, value: timerViewModel.remainingTime)
        }
    }
    
    func displayTime(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%01d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct TimerAbstractView: View {
    @StateObject var timerViewModel: TimerViewModel
    let timerColor: Color = .white
    @State private var animating: Bool = false

    var lineWidth: CGFloat { 
        circleWidth / 10
    }

    let circleWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .foregroundStyle(animating ? timerColor : timerColor.opacity(0.2))
                .padding(lineWidth)
                .frame(width: circleWidth, height: circleWidth)
            Circle()
                .trim(from: 0.0, to: min(1-timerViewModel.progress, 1.0))
                .stroke(timerColor, style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round,
                    lineJoin: .miter))
                .rotationEffect(.degrees(-90))
                .shadow(radius: 2)
                .padding(lineWidth)
                .frame(width: circleWidth, height: circleWidth)
            Rectangle()
                .cornerRadius(lineWidth)
                .frame(width: lineWidth, height: (circleWidth - lineWidth) / 4)
                .foregroundStyle(timerColor)
                .offset(y: -(circleWidth - lineWidth) / 6)
                .rotationEffect(.degrees(CGFloat(360) * (1 - timerViewModel.progress)))
                .shadow(radius: 1)
        }
        .scaleEffect(animating ? 1.15 : 1)
        .rotationEffect(.degrees(animating ? 45 : 0))
        .animation(
            animating
                ? Animation.easeInOut(duration: 0.1).repeatForever(autoreverses: true)
                : .linear,
            value: animating
        )
        .animation(.linear, value: timerViewModel.remainingTime)
        .onAppear {
            if timerViewModel.remainingTime <= 0 {
                animating = true
            }
        }
        .onChange(of: timerViewModel.remainingTime) { newValue in
            if newValue <= 0 {
                animating = true
            }
        }
        .aspectRatio(contentMode: .fit)
    }
}

class TimerAbstractInstance: NotificationInstance {
    var id: UUID
    var category: String {
        return "timer_\(id)"
    }
    var ty: NotificationType = .always
    var icon: (NotchViewModel) -> any View
    var action: (NotchViewModel) -> Void
    let timerViewModel: TimerViewModel

    init(timerViewModel: TimerViewModel) {
        self.id = timerViewModel.id
        self.timerViewModel = timerViewModel
        self.icon = { notchViewModel in
            TimerAbstractView(timerViewModel: timerViewModel, circleWidth: notchViewModel.deviceNotchRect.height * 0.8)
        }
        self.action = { notchViewModel in
            notchViewModel.notchOpen(contentType: .timer)
        }
    }
}
