import Foundation

class Windows: ObservableObject, Switches {
    static let shared = Windows()
    @Published var focusedWindow: Window? = nil
    @Published var inner: [Window] = []
    
    func getSwitches() -> [any Switchable] {
        return inner
    }
    
    @MainActor
    func addWindow(window: Window) {
        for innerWindow in inner {
            if innerWindow.axWindow == window.axWindow {
                return
            }
        }
        inner.append(window)
        sort()
    }
    
    @MainActor
    func peekWindow(window: Window) {
        for other in inner {
            if other.globalOrder > window.globalOrder {
                other.globalOrder -= 1
            }
        }
        window.globalOrder = inner.count - 1
        sort()
    }
    
    @MainActor
    func removeWindow(axWindow: AxWindow) {
        guard let index = inner.firstIndex(where: { axWindow == $0.axWindow }) else { return }
        let removedWindow = inner.remove(at: index)
        for window in inner {
            if window.globalOrder > removedWindow.globalOrder {
                window.globalOrder -= 1
            }
        }
    }
    
    @MainActor
    func sort() {
        inner.sort {
            return $0.globalOrder > $1.globalOrder
        }
    }
}

