//
//  TrayDropMenubarView.swift
//  Peninsula
//
//  Created by Celve on 12/30/24.
//
import SwiftUI

struct TrayDropMenubarView: View {
    let notchViewModel: NotchViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                notchViewModel.contentType = .traySettings
            }) {
                Image(systemName: "gear")
            }.buttonStyle(.plain)
        }
    }
}
