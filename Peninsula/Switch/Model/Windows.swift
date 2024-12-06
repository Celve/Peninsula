import Foundation

// Static only.
class Windows: ObservableObject {
    static let shared = Windows()
    @Published var focusedWindow: Window? = nil
    @Published var inner: [Window] = []
    
    @MainActor
    func addWindow(application: Application, axWindow: AxWindow) {
        let window = Window(application: application, axWindow: axWindow, globalOrder: Int32(inner.count))
        for innerWindow in inner {
            if innerWindow.axWindow == axWindow {
                return 
            }
        }
        inner.append(window)
        application.windows.append(window)
        sort()
    }
    
    @MainActor
    func focusOrAddWindow(application: Application, axWindow: AxWindow) -> Window {
        if let focusedWindow = inner.first(where: { axWindow == $0.axWindow }) {
            for window in inner {
                if window.globalOrder > focusedWindow.globalOrder {
                    window.globalOrder -= 1
                }
            }
            focusedWindow.globalOrder = Int32(inner.count) - 1
            sort()
            return focusedWindow
        } else {
            let window = Window(application: application, axWindow: axWindow, globalOrder: Int32(inner.count))
            inner.append(window)
            application.windows.append(window)
            sort()
            return window
        }
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

