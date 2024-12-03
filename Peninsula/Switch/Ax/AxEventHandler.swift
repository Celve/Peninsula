//
//  AxEventHandler.swift
//  Island
//
//  Created by Celve on 9/22/24.
//

import Cocoa
import ApplicationServices.HIServices.AXUIElement
import ApplicationServices.HIServices.AXNotificationConstants

let globalTimeoutInSeconds: Float = 120
let retryDelayInMilliseconds = 250

func segAxGlobalTimeout() {
    // we add 5s to make sure to not do an extra retry
    AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), globalTimeoutInSeconds + 5)
}

// if the window server is busy, it may not reply to AX calls. We retry right before the call times-out and returns a bogus value
func retryAxCallUntilTimeout(group: DispatchGroup? = nil, timeoutInSeconds: Double = Double(globalTimeoutInSeconds), fn: @escaping () throws -> Void, _ startTime: DispatchTime = DispatchTime.now()) {
    group?.enter()
    BackgroundWork.axCallsQueue.async {
        retryAxCallUntilTimeout_(group, timeoutInSeconds, fn, startTime)
    }
}

func retryAxCallUntilTimeout_(_ group: DispatchGroup?, _ timeoutInSeconds: Double, _ fn: @escaping () throws -> Void, _ startTime: DispatchTime = DispatchTime.now()) {
    do {
        try fn()
        group?.leave()
    } catch {
        let timePassedInSeconds = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
        if timePassedInSeconds < timeoutInSeconds {
            BackgroundWork.axCallsQueue.asyncAfter(deadline: .now() + .milliseconds(retryDelayInMilliseconds)) {
                retryAxCallUntilTimeout_(group, timeoutInSeconds, fn, startTime)
            }
        }
    }
}
