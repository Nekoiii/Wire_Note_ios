import SwiftUI

struct InstrumentalToggle: View {
    @Binding var isMakeInstrumental: Bool
    
    var body: some View {
        Toggle(isOn: $isMakeInstrumental) {
            Text("Make It Instrumental")
        }
    }
}
