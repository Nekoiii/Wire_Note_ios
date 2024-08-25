import SwiftUI

struct DetectWireButton: View {
    @Binding var isDetectWire: Bool

    var body: some View {
        Toggle(isOn: $isDetectWire) {
            Text("Detect Wire")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 5)
        }.toggleStyle(SwitchToggleStyle(tint: .accent2))
    }
}
