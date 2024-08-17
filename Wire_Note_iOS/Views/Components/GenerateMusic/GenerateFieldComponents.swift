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
        TextArea(
            text: $title,
            title: "Title",
            maxCharacters: 80
        )
    }
}

struct GenerateStyleTextField: View {
    @Binding var style: String
    var body: some View {
        TextArea(
            text: $style,
            title: "Style of Music",
            maxCharacters: 120
        )
    }
}

struct GeneratePromptTextField: View {
    @Binding var prompt: String
    var generateMode: GenerateMode

    var body: some View {
        TextArea(
            text: $prompt,
            title: generateMode == .customGenerate ? "Lyrics" : "Song description",
            maxCharacters: generateMode == .customGenerate ? 3000 : 200,
            minHeight: 200
        )
    }
}
