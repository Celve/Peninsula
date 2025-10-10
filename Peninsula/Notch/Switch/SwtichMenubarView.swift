import SwiftUI

struct SwitchMenubarView: View {
    @ObservedObject var galleryModel = GalleryModel.shared
    
    var body: some View {
        HStack {
            Button(action: {
                galleryModel.currentItem = .switchSettings
            }) {
                Image(systemName: "gear")
            }.buttonStyle(.plain)
        }
    }
}
