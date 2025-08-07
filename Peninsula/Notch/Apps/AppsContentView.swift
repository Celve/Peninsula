//
//  SwitchContentView.swift
//  Island
//
//  Created by Celve on 9/22/24.
//

import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

class AppsViewModel: ObservableObject {
    @Published var title: String = "None"
}

struct AppsContentView: View {
    let vm: NotchViewModel
    @StateObject var windows = Windows.shared
    @StateObject var svm = AppsViewModel()
    @State private var scrollOffset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var scrollViewWidth: CGFloat = 0
    
    let rows = [
        GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 12)
    ]
    
    var filteredWindows: [Window] {
        windows.coll.filter {
            if let frame = try? $0.axElement.frame() {
                return vm.cgScreenRect.intersects(frame)
            }
            return false
        }
    }
    
    var showRightIndicator: Bool {
        scrollOffset + scrollViewWidth < contentWidth - 5
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: rows, spacing: 12) {
                        ForEach(Array(filteredWindows.enumerated()), id: \.offset) { index, window in
                            AppIcon(name: window.title, image: (window.application.icon ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil) ?? NSImage()), vm: vm, svm: svm)
                                .frame(width: 50, height: 50)
                                .onTapGesture {
                                    window.focus()
                                    vm.notchClose()
                                }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.leading, 16)
                    .padding(.trailing, showRightIndicator ? 8 : 16)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    contentWidth = geo.size.width
                                }
                                .onChange(of: geo.size.width) { newValue in
                                    contentWidth = newValue
                                }
                        }
                    )
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                scrollViewWidth = geo.size.width
                            }
                            .onChange(of: geo.size.width) { newValue in
                                scrollViewWidth = newValue
                            }
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("scroll")).origin.x)
                    }
                )
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = -value
                }
                
                if showRightIndicator {
                    VStack {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 20, height: 20)
                            )
                    }
                    .padding(.trailing, 12)
                    .transition(.opacity.combined(with: .scale))
                    .animation(vm.normalAnimation, value: showRightIndicator)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Text(svm.title)
                .lineLimit(1)
                .opacity(svm.title == "None" ? 0 : 1)
                .transition(.opacity)
                .animation(vm.normalAnimation, value: svm.title)
                .contentTransition(.numericText())
                .padding(.bottom, 8)
        }
    }
}


private struct AppIcon: View {
    let name: String
    let image: NSImage
    @StateObject var vm: NotchViewModel
    @State var hover: Bool = false
    @StateObject var svm: AppsViewModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(hover ? 0.15 : 0.05))
                .animation(.spring(), value: hover)
            
            Image(nsImage: image)
                .resizable()
                .contentShape(Rectangle())
                .aspectRatio(contentMode: .fit)
                .padding(8)
                .scaleEffect(hover ? 1.1 : 1)
                .animation(.spring(), value: hover)
                .onHover { hover in
                    self.hover = hover
                    svm.title = hover ? name : "None"
                }
        }
        .frame(width: 50, height: 50)
    }
}

