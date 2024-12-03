//
//  HeaderView.swift
//  Island
//
//  Created by Celve on 9/21/24.
//

import ColorfulX
import SwiftUI

struct HeaderView<Headline: View, MenuBar: View>: View {
    var headline: Headline
    var menubar: MenuBar
        
    var body: some View {
        HStack(spacing: 0) {
            headline
            Spacer()
            menubar
        }
        .font(.system(.headline, design: .rounded))
    }
}
