import SwiftUI

class GenerateMusicViewModel: ObservableObject {
    @Published var loadingState: LoadingState?
    @Published var isMakeInstrumental: Bool
    @Published var isDetectWire: Bool = true

    private(set) var videoToMusicData: VideoToMusicData?

    init(videoToMusicData: VideoToMusicData?, isMakeInstrumental: Bool = false) {
        self.videoToMusicData = videoToMusicData
        self.isMakeInstrumental = isMakeInstrumental
    }

    func setVideoToMusicData(_ videoToMusicData: VideoToMusicData) {
        self.videoToMusicData = videoToMusicData
    }

    func generateMusicWithDescription() async {
        guard let videoToMusicData = videoToMusicData else { return }

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
