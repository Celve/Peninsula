import SwiftUI

// ViewModel for AppsView: holds paging/cache state and window data

class AppsViewModel: ObservableObject {
    @Published var title: String = "None"
    
    @Published var currentPage: Int = 0
    @Published var cachedFilteredWindows: [Window] = []
    @Published var lastScreenRect: CGRect = .zero

    // Data source for windows
    let windows = Windows.shared

    // Paging configuration
    @Published var itemsPerRow: Int = 10
    @Published var rowsPerPage: Int = 2
    @Published var itemSize = CGSize(width: 40, height: 40)
    var pageCapacity: Int { itemsPerRow * rowsPerPage }

    // Refresh filtered windows for a given screen rect
    func refreshFilteredWindows(for screenRect: CGRect) {
        lastScreenRect = screenRect
        cachedFilteredWindows = windows.coll.filter {
            if let frame = try? $0.axElement.frame() {
                return screenRect.intersects(frame)
            }
            return false
        }
    }

    // MARK: - Paging helpers (moved from view)
    var pageCount: Int {
        let count = cachedFilteredWindows.count
        return max(1, Int(ceil(Double(count) / Double(pageCapacity))))
    }

    var currentPageClamped: Int {
        let total = pageCount
        return min(max(0, currentPage), max(0, total - 1))
    }

    func windowsForCurrentPage() -> ArraySlice<Window> {
        let p = currentPageClamped
        let start = p * pageCapacity
        let end = min(start + pageCapacity, cachedFilteredWindows.count)
        guard start < end else { return [] }
        return cachedFilteredWindows[start..<end]
    }

    func goPrev() {
        currentPage = max(0, currentPageClamped - 1)
    }

    func goNext() {
        currentPage = min(pageCount - 1, currentPageClamped + 1)
    }

    func clampCurrentPageIfNeeded() {
        let clamped = currentPageClamped
        if clamped != currentPage { currentPage = clamped }
    }
}
