//
//  TrayDropMenubarView.swift
//  Peninsula
//
//  Created by Celve on 12/30/24.
//
import SwiftUI

struct TrayDropMenubarView: View {
    @ObservedObject var galleryModel = GalleryModel.shared
    
    var body: some View {
        HStack {
            Button(action: {
                galleryModel.currentItem = .traySettings
            }) {
                Image(systemName: "gear")
            }.buttonStyle(.plain)
        }
    }
}
