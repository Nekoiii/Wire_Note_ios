import SwiftUI

class VideoToMusicData: ObservableObject {
    @Published var originVideoUrl: URL?
    @Published var description: String = ""
    @Published var generatedAudioUrls: [URL] = []
    @Published var downloadedGeneratedAudioUrls: [URL] = []

    var outputDirectoryURL: URL

    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        outputDirectoryURL = documentsPath.appendingPathComponent("VideoToMusicPages_outputs")
        guard createDirectoryIfNotExists(at: outputDirectoryURL) else { return }
    }
}
