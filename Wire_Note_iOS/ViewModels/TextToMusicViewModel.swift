import SwiftUI

class TextToMusicViewModel: ObservableObject {
    @Published var generateMode: GenerateMode = .generate
    @Published var prompt: String = ""
    @Published var style: String = ""
    @Published var title: String = ""
    @Published var isMakeInstrumental: Bool = false
    @Published var generatedAudioUrls: [URL] = []

    func generatemMusic() async {
        let generatePrompt = prompt.isEmpty ? DefaultPrompts.sunoGeneratePrompt : prompt
        let generateTags = style.isEmpty ? DefaultPrompts.sunoGenerateTags : style
        let generateTitle = title.isEmpty ? DefaultPrompts.sunoGenerateTitle : title
        let generateIsMakeInstrumental = (prompt.isEmpty && generateMode == .customGenerate) ? true : isMakeInstrumental

        let sunoGenerateAPI = SunoGenerateAPI(generateMode: generateMode)

        let audioUrls = await sunoGenerateAPI.generatemMusic(generateMode: generateMode, prompt: generatePrompt, tags: generateTags, title: generateTitle, makeInstrumental: generateIsMakeInstrumental)
        generatedAudioUrls = audioUrls
        Task {
            await sunoGenerateAPI.downloadAndSaveFiles(audioUrls: audioUrls)
        }
    }
}
