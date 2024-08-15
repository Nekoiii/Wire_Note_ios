import SwiftUI

class TextToMusicViewModel: ObservableObject {
    @Published var generateMode: GenerateMode = .generate
    @Published var prompt: String = ""
    @Published var style: String = ""
    @Published var title: String = ""
    @Published var isMakeInstrumental: Bool = false
    @Published var generatedAudioUrls: [URL] = []

    func generatemMusic() async {
        let generatePrompt = prompt.isEmpty ? "Good morning" : prompt
        let generateTags = style.isEmpty ? "kpop, Chinese" : style
        let generateTitle = title.isEmpty ? "My Song" : title
        let generateIsMakeInstrumental = (prompt.isEmpty && generateMode == .customGenerate) ? true : isMakeInstrumental

        let sunoGenerateAPI = SunoGenerateAPI(generateMode: generateMode)

        let audioUrls = await sunoGenerateAPI.generatemMusic(generateMode: generateMode, prompt: generatePrompt, tags: generateTags, title: generateTitle, makeInstrumental: generateIsMakeInstrumental)
        generatedAudioUrls = audioUrls
        Task {
            await sunoGenerateAPI.downloadAndSaveFiles(audioUrls: audioUrls)
        }
    }
}
