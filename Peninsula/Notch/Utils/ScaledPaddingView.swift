//
//  View.swift
//  Island
//
//  Created by Celve on 9/22/24.
//

import SwiftUI

struct ScaledPaddingView<Inner: View>: View {
    let inner: Inner
    let percentage: CGFloat
    
    @State var paddingX: CGFloat = 0
    @State var paddingY: CGFloat = 0

    var body: some View {
        inner
            .padding(.horizontal, paddingX)
            .padding(.vertical, paddingY)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            paddingX = geometry.frame(in: .local).width * percentage
                            paddingY = geometry.frame(in: .local).height * percentage
                        }
                        .onChange(of: geometry.frame(in: .local)) {
                            paddingX = geometry.frame(in: .local).width * percentage
                            paddingY = geometry.frame(in: .local).height * percentage
                        }
                }
            )
    }
}
