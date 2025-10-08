//
//  SwitchContentView.swift
//  Island
//
//  Created by Celve on 9/22/24.
//

import SwiftUI


struct AppsView: View {
    let vm: NotchViewModel
    @StateObject var appsViewModel: AppsViewModel = AppsViewModel()
    // moved into AppsViewModel: currentPage, cachedFilteredWindows, lastScreenRect
    
    // Paging configuration moved to ViewModel; derive layout from it
    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(appsViewModel.itemSize.width), spacing: 12), count: appsViewModel.itemsPerRow)
    }
    private var gridHeight: CGFloat {
        // rows * cellHeight + (rows-1) * rowSpacing + top/bottom padding (8 + 8)
        let rows = CGFloat(appsViewModel.rowsPerPage)
        return rows * appsViewModel.itemSize.height + (rows - 1) * 12
    }
    
    // Data-driven pieces moved into AppsViewModel (pageCount, clamping, slicing)
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                    ForEach(Array(appsViewModel.windowsForCurrentPage()), id: \.id) { window in
                        AppIcon(name: window.title, image: (window.application.icon ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil) ?? NSImage()), size: appsViewModel.itemSize, vm: vm, appsViewModel: appsViewModel)
                            .onTapGesture {
                                window.focus()
                                vm.notchClose()
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
            .frame(height: gridHeight, alignment: .top)
            .overlay(alignment: .leading) {
                if appsViewModel.currentPageClamped > 0 {
                    Button {
                        withAnimation(vm.normalAnimation) { appsViewModel.goPrev() }
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
                if appsViewModel.currentPageClamped < appsViewModel.pageCount - 1 {
                    Button {
                        withAnimation(vm.normalAnimation) { appsViewModel.goNext() }
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
                appsViewModel.refreshFilteredWindows(for: vm.cgScreenRect)
                appsViewModel.clampCurrentPageIfNeeded()
            }
            .onChange(of: vm.cgScreenRect) { newValue in
                appsViewModel.refreshFilteredWindows(for: newValue)
                appsViewModel.clampCurrentPageIfNeeded()
            }
            .onReceive(appsViewModel.windows.$coll) { _ in
                appsViewModel.refreshFilteredWindows(for: vm.cgScreenRect)
                appsViewModel.clampCurrentPageIfNeeded()
            }
            .onChange(of: appsViewModel.itemsPerRow) { _ in
                appsViewModel.clampCurrentPageIfNeeded()
            }
            .onChange(of: appsViewModel.rowsPerPage) { _ in
                appsViewModel.clampCurrentPageIfNeeded()
            }
            
            Text(appsViewModel.title)
                .lineLimit(1)
                .opacity(appsViewModel.title == "None" ? 0 : 1)
                .transition(.opacity)
                .animation(vm.normalAnimation, value: appsViewModel.title)
                .contentTransition(.numericText())
                .padding(.bottom, 4)
        }
    }
}


private struct AppIcon: View {
    let name: String
    let image: NSImage
    let size: CGSize
    let vm: NotchViewModel
    @State var hover: Bool = false
    @ObservedObject var appsViewModel: AppsViewModel

    var body: some View {
        ZStack {
            Image(nsImage: image)
                .resizable()
                .contentShape(Rectangle())
                .aspectRatio(contentMode: .fit)
                .scaleEffect(hover ? 1.1 : 1)
        }
        .frame(width: size.width, height: size.height)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hover)
        .onHover { hovering in
            if self.hover != hovering {
                self.hover = hovering
                appsViewModel.title = hovering ? name : "None"
            }
        }
    }
}
