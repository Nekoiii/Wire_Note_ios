import SwiftUI

struct SolidButtonStyle: ButtonStyle {
    let buttonColor: Color
    let isDisable: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(buttonColor)
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .opacity(isDisable ? 0.3 : 1.0)
    }
}
