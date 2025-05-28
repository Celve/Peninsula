import SwiftUI

struct SwitchMenubarView: View {
    let notchViewModel: NotchViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                notchViewModel.contentType = .switchSettings
            }) {
                Image(systemName: "gear")
            }.buttonStyle(.plain)
        }
    }
}
