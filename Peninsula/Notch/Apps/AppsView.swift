//
//  SwitchContentView.swift
//  Island
//
//  Created by Celve on 9/22/24.
//

import SwiftUI


struct AppsView: View {
    let vm: NotchViewModel
    @StateObject var windows = Windows.shared
    @StateObject var appsViewModel: AppsViewModel = AppsViewModel()
    // moved into AppsViewModel: currentPage, cachedFilteredWindows, lastScreenRect
    
    // Paging configuration
    private let itemsPerRow: Int = 9
    private let rowsPerPage: Int = 2
    private var pageCapacity: Int { itemsPerRow * rowsPerPage }
    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(50), spacing: 12), count: itemsPerRow)
    }
    private var gridHeight: CGFloat {
        // rows * cellHeight + (rows-1) * rowSpacing + top/bottom padding (8 + 8)
        let rows = CGFloat(rowsPerPage)
        return rows * 45 + (rows - 1) * 12 + 16
    }
    
    var filteredWindows: [Window] {
        // Only recalculate if screen rect changed or windows changed
        if appsViewModel.lastScreenRect != vm.cgScreenRect || appsViewModel.cachedFilteredWindows.isEmpty {
            return windows.coll.filter {
                if let frame = try? $0.axElement.frame() {
                    return vm.cgScreenRect.intersects(frame)
                }
                return false
            }
        }
        return appsViewModel.cachedFilteredWindows
    }
    
    private var pageCount: Int {
        let count = filteredWindows.count
        return max(1, Int(ceil(Double(count) / Double(pageCapacity))))
    }
    
    private var currentPageClamped: Int {
        min(max(0, appsViewModel.currentPage), max(0, pageCount - 1))
    }
    
    private var windowsForCurrentPage: ArraySlice<Window> {
        let p = currentPageClamped
        let start = p * pageCapacity
        let end = min(start + pageCapacity, filteredWindows.count)
        guard start < end else { return [] }
        return filteredWindows[start..<end]
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                    ForEach(Array(windowsForCurrentPage), id: \.id) { window in
                        AppIcon(name: window.title, image: (window.application.icon ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil) ?? NSImage()), vm: vm, appsViewModel: appsViewModel)
                            .frame(width: 45, height: 45)
                            .onTapGesture {
                                window.focus()
                                vm.notchClose()
                            }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
            .frame(height: gridHeight, alignment: .top)
            .overlay(alignment: .leading) {
                if currentPageClamped > 0 {
                    Button {
                        withAnimation(vm.normalAnimation) { appsViewModel.currentPage = max(0, currentPageClamped - 1) }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.black.opacity(0.25)))
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)
                }
            }
            .overlay(alignment: .trailing) {
                if currentPageClamped < pageCount - 1 {
                    Button {
                        withAnimation(vm.normalAnimation) { appsViewModel.currentPage = min(pageCount - 1, currentPageClamped + 1) }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.black.opacity(0.25)))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }
            }
            .onAppear {
                appsViewModel.cachedFilteredWindows = filteredWindows
                appsViewModel.lastScreenRect = vm.cgScreenRect
                if currentPageClamped != appsViewModel.currentPage { appsViewModel.currentPage = currentPageClamped }
            }
            .onChange(of: vm.cgScreenRect) { newValue in
                appsViewModel.lastScreenRect = newValue
                appsViewModel.cachedFilteredWindows = filteredWindows
                if currentPageClamped != appsViewModel.currentPage { appsViewModel.currentPage = currentPageClamped }
            }
            
            Text(appsViewModel.title)
                .lineLimit(1)
                .opacity(appsViewModel.title == "None" ? 0 : 1)
                .transition(.opacity)
                .animation(vm.normalAnimation, value: appsViewModel.title)
                .contentTransition(.numericText())
                .padding(.bottom, 8)
        }
    }
}


private struct AppIcon: View {
    let name: String
    let image: NSImage
    let vm: NotchViewModel
    @State var hover: Bool = false
    @ObservedObject var appsViewModel: AppsViewModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(hover ? 0.15 : 0.05))
            
            Image(nsImage: image)
                .resizable()
                .contentShape(Rectangle())
                .aspectRatio(contentMode: .fit)
                .padding(8)
                .scaleEffect(hover ? 1.1 : 1)
        }
        .frame(width: 50, height: 50)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hover)
        .onHover { hovering in
            if self.hover != hovering {
                self.hover = hovering
                appsViewModel.title = hovering ? name : "None"
            }
        }
    }
}
