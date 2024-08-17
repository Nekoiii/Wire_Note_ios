import SwiftUI

struct GenerateModePicker: View {
    @Binding var generateMode: GenerateMode

    var body: some View {
        Picker("Generate Mode", selection: $generateMode) {
            Text("Generate").tag(GenerateMode.generate)
            Text("Custom Generate").tag(GenerateMode.customGenerate)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.vertical, 10)
    }
}

struct GenerateTitleTextField: View {
    @Binding var title: String
    var body: some View {
        TextField("Enter title", text: $title)
    }
}

struct GenerateStyleTextField: View {
    @Binding var style: String
    var body: some View {
        TextField("Enter style", text: $style)
    }
}

struct GeneratePromptTextField: View {
    @Binding var prompt: String
    var generateMode: GenerateMode
    var maxCharacters: Int = 200

    var body: some View {
        TextArea(
            text: $prompt,
            title: generateMode == .customGenerate ? "Lyrics" : "Song description",
            maxCharacters: 200
        )
    }
}
