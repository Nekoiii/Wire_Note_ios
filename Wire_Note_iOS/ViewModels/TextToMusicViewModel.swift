import SwiftUI

class TextToMusicViewModel: ObservableObject {
    @Published var generateMode: GenerateMode = .generate
    @Published var prompt: String = ""
    @Published var style: String = ""
    @Published var title: String = ""
    @Published var isMakeInstrumental: Bool = false
    @Published var generatedAudioUrls: [URL] = []
}
