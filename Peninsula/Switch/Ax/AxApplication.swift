import ApplicationServices.HIServices.AXUIElement

class AxApplication: AxElement {
    override init(element: AXUIElement) {
        super.init(element: element)
    }
    
    func windows() throws -> [AxWindow]? {
        guard let elements = try attribute(kAXWindowsAttribute, [AXUIElement].self) else {
            return nil
        }
        return elements.map { AxWindow(element: $0) }
    }
    
    func focusedWindow() throws -> AxWindow? {
        if let element = try attribute(kAXFocusedWindowAttribute, AXUIElement.self) {
            return AxWindow(element: element)
        } else {
            return nil
        }
    }
}
