import SwiftUI

class GenerateMusicViewModel: ObservableObject {
    @EnvironmentObject var videoToMusicData: VideoToMusicData

    @Published var loadingState: LoadingState?
    @Published var isMakeInstrumental: Bool
    @Published var isDetectWire: Bool = true

    init(isMakeInstrumental: Bool = false) {
        self.isMakeInstrumental = isMakeInstrumental
    }

    func generateMusicWithDescription() async {
        let generatePrompt = videoToMusicData.description
        let generateIsMakeInstrumental = isMakeInstrumental
        let generateMode = GenerateMode.generate

        let sunoGenerateAPI = SunoGenerateAPI(generateMode: generateMode)

        let audioUrls = await sunoGenerateAPI.generatemMusic(generateMode: generateMode, prompt: generatePrompt, makeInstrumental: generateIsMakeInstrumental)
        videoToMusicData.generatedAudioUrls = audioUrls
        Task {
            loadingState = .download_file
            videoToMusicData.downloadedGeneratedAudioUrls = await sunoGenerateAPI.downloadAndSaveFiles(audioUrls: audioUrls)
            loadingState = nil
        }
    }
}
