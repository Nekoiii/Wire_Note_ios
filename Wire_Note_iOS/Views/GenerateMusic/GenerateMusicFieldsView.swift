import SwiftUI

struct InstrumentalToggle: View {
    @Binding var generateMode: GenerateMode
    @Binding var prompt: String
    @Binding var style: String
    @Binding var title: String
    
    var body: some View {
        Group {
            TextField("Enter \(generateMode == .customGenerate ? "lyrics" : "prompt")", text: $prompt)
            if generateMode == .customGenerate {
                TextField("Enter style", text: $style)
                TextField("Enter title", text: $title)
            }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding(.vertical, 5)
    }
}
