//
//  TimerModel.swift
//  Peninsula
//
//  Created by Celve on 5/6/25.
//

import Swift
import Foundation

class TimerViewModel: Hashable, ObservableObject {
    let id = UUID()
    var timer: Timer? = nil
    @Published var totalTime: Int
    @Published var elapsedTime: Int = 0
    @Published var isRunning: Bool = false
    @Published var description: String 
    var callback: () -> Void
    
    init(time: Int, description: String, callback: @escaping () -> Void) {
        self.totalTime = time
        self.description = description
        self.callback = callback
    }
    
    var remainingTime: Int {
        totalTime - elapsedTime
    }
    
    var progress: CGFloat {
        CGFloat(totalTime - remainingTime) / CGFloat(totalTime)
    }
    
    func start() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            if remainingTime > 0 {
                self.elapsedTime += 1
            } else {
                self.stop()
                self.callback()
            }
        }
    }
    
    func stop() {
        isRunning = false
        timer?.invalidate()
    }
    
    func reset() {
        self.elapsedTime = 0
    }
    
    var playButtonDisabled: Bool {
        guard remainingTime > 0, !isRunning else { return true}
        return false
    }
    
    var pauseButtonDisabled: Bool {
        guard remainingTime > 0, isRunning else { return true }
        return false
    }
    
    var resetButtonDisabled: Bool {
        guard remainingTime != totalTime, !isRunning else { return true }
        return false
    }
    
    static func == (lhs: TimerViewModel, rhs: TimerViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class TimerModel: ObservableObject {
    static let shared = TimerModel(times: [])
    @Published var viewModels: [TimerViewModel] = []
    var absInsts: [TimerAbstractInstance] = []
    @Published var description: String = "None" // placeholder is needed, otherwise the view will not show

    init(times: [Int]) {
        for time in times {
            self.add(time: time, description: "")
        }
    }

    func remove(id: UUID) {
        viewModels.removeAll { $0.id == id }
        absInsts.removeAll { $0.id == id }
        NotificationModel.shared.remove(ty: .always, category: "timer_\(id)")
    }

    func clearExpiredTimers() {
        // Get all expired timer IDs
        let expiredTimerIDs = viewModels
            .filter { $0.remainingTime <= 0 }
            .map { $0.id }
        
        // Remove each expired timer
        for id in expiredTimerIDs {
            remove(id: id)
        }
    }

    func add(time: Int, description: String) {
        let timer = TimerViewModel(time: time, description: description, callback: {})
        viewModels.append(timer)
        timer.start()
        
        let absInst = TimerAbstractInstance(timerViewModel: timer)
        absInsts.append(absInst)
        NotificationModel.shared.add(item: absInst)
    }

    func setDescription(description: String) {
        self.description = description
    }
}
