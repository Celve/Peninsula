import SwiftUI

struct TextButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Text(text)
            .foregroundColor(.black)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerSize: .init(width: 4, height: 4))
                    .foregroundStyle(.white)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                action()
            }
    }
}
