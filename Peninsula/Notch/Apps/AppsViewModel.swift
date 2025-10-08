import SwiftUI

class AppsViewModel: ObservableObject {
    @Published var title: String = "None"
    @Published var type: NotchComponentType = .area(size: CGSize.zero)
    // Paging and caching state moved from AppsView
    @Published var currentPage: Int = 0
    @Published var cachedFilteredWindows: [Window] = []
    @Published var lastScreenRect: CGRect = .zero
}
