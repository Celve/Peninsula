import Foundation

// queues and dedicated threads to observe background events such as keyboard inputs, or accessibility events
class BackgroundWork {
    static var synchronizationQueue: DispatchQueue!
    static var axCallsQueue: DispatchQueue!
    static var commandQueue: DispatchQueue!
    static var accessibilityEventsThread: BackgroundThreadWithRunLoop!

    // we cap concurrent tasks to .processorCount to avoid thread explosion on the .global queue
    static let globalSemaphore = DispatchSemaphore(value: ProcessInfo.processInfo.processorCount)
    // Thread.start() is async; we use a semaphore to ensure threads are actually ready before we continue the launch sequence
    static let threadStartSemaphore = DispatchSemaphore(value: 0)

    // swift static variables are lazy; we artificially force the threads to init
    static func start() {
        synchronizationQueue = DispatchQueue.globalConcurrent("synchronizationQueue", .userInteractive)
        axCallsQueue = DispatchQueue.globalConcurrent("axCallsQueue", .userInteractive)
        commandQueue = DispatchQueue.globalConcurrent("commandQueue", .userInteractive)
        accessibilityEventsThread = BackgroundThreadWithRunLoop("accessibilityEventsThread", .userInteractive)
    }
}

extension DispatchQueue {
    static func globalConcurrent(_ label: String, _ qos: DispatchQoS) -> DispatchQueue {
        return DispatchQueue(label: label, attributes: .concurrent, target: .global(qos: qos.qosClass))
    }
    
    func taskRestricted(fn: @escaping @Sendable () async -> Void) {
        execRestricted {
            Task(priority: .userInteractive) {
                await fn()
            }
            BackgroundWork.globalSemaphore.signal()
        }
    }

    func asyncRestricted(deadline: DispatchTime? = nil, fn: @escaping @Sendable () -> Void) {
        execRestricted {
            fn()
            BackgroundWork.globalSemaphore.signal()
        }
    }
    
    private func execRestricted(deadline: DispatchTime? = nil, block: @escaping @Sendable @convention(block) () -> Void) {
        BackgroundWork.globalSemaphore.wait()
        if let deadline = deadline {
            asyncAfter(deadline: deadline, execute: block)
        } else {
            async(execute: block)
        }
    }
}

class BackgroundThreadWithRunLoop {
    var thread: Thread?
    var runLoop: CFRunLoop?
    var hasSentSemaphoreSignal = false

    init(_ name: String, _ qos: DispatchQoS) {
        thread = Thread {
            self.runLoop = CFRunLoopGetCurrent()
            while !self.thread!.isCancelled {
                if !self.hasSentSemaphoreSignal {
                    BackgroundWork.threadStartSemaphore.signal()
                    self.hasSentSemaphoreSignal = true
                }
                CFRunLoopRun()
                // avoid tight loop while waiting for the first runloop source to be added
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
        thread!.name = name
        thread!.qualityOfService = {
            switch qos {
            case .userInteractive:
                return .userInteractive
            case .userInitiated:
                return .userInitiated
            case .default:
                return .default
            case .utility:
                return .utility
            case .background:
                return .background
            case .unspecified:
                return .default 
            default:
                return .default
            }
        }()
        thread!.start()
        BackgroundWork.threadStartSemaphore.wait()
    }
}
