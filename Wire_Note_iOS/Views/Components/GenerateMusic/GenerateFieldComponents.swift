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
            Text("Make It Instrumental")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 5)
        }.toggleStyle(SwitchToggleStyle(tint: .accent2))
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

struct GenerateMusicButton: View {
    @Binding var isDisable: Bool
    @Binding var generatedAudioUrls: [URL]

    var prompt: String
    var style: String
    var title: String
    var isMakeInstrumental: Bool
    var generateMode: GenerateMode

    var body: some View {
        Button(action: {
            Task {
                await generateMusic()
            }
        }) {
            Text("Generate music")
        }
        .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: isDisable))
        .disabled(isDisable)
    }

    private func generateMusic() async {
        let generatePrompt = prompt.isEmpty ?
            (title.isEmpty ? DefaultPrompts.sunoGeneratePrompt : title)
            : prompt
        let generateTags = style.isEmpty ? DefaultPrompts.sunoGenerateTags : style
        let generateTitle = title.isEmpty ? DefaultPrompts.sunoGenerateTitle : title
        let generateIsMakeInstrumental = (prompt.isEmpty && generateMode == .customGenerate) ? true : isMakeInstrumental

        let sunoGenerateAPI = SunoGenerateAPI(generateMode: generateMode)

        let audioUrls = await sunoGenerateAPI.generateMusic(generateMode: generateMode, prompt: generatePrompt, tags: generateTags, title: generateTitle, makeInstrumental: generateIsMakeInstrumental)
        generatedAudioUrls = audioUrls
        Task {
            await sunoGenerateAPI.downloadAndSaveFiles(audioUrls: audioUrls)
        }
    }
}
