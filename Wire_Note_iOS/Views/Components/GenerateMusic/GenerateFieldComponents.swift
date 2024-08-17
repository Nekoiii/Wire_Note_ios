import SwiftUI

struct GenerateModePicker: View {
    @Binding var selectedMode: GenerateMode

    var body: some View {
        TabView(
            selectedIndex: Binding(
                get: {
                    selectedMode.index
                },
                set: { newIndex in
                    selectedMode = GenerateMode.allCases[newIndex]
                }
            ), tabs: GenerateMode.allCases.map { $0.title }
        ) {}
    }
}

struct InstrumentalToggleView: View {
    @Binding var isMakeInstrumental: Bool

    var body: some View {
        Toggle(isOn: $isMakeInstrumental) {
            Text("Make It Instrumental").font(.headline)
        }.toggleStyle(
            SwitchToggleStyle(tint: .accent2)
        )
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
            minHeight: 150
        )
    }
}
