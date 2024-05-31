import SwiftUI

struct BorderedButtonStyle: ButtonStyle {
    let borderColor: Color
    let isDisable: Bool

    init(borderColor: Color, isDisable: Bool = false) {
            self.borderColor = borderColor
            self.isDisable = isDisable
        }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.clear)
            .foregroundColor(borderColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            .opacity(isDisable ? 0.3 : 1.0)
    }
}
