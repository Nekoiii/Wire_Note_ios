import SwiftUI

class VideoToMusicData: ObservableObject {
    @Published var videoUrl: URL?
    @Published var description: String = ""
    @Published var generatedAudioUrls: [URL] = []
}
