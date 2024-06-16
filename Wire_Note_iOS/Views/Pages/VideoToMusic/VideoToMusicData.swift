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
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: outputDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                print("Directory created at: \(outputDirectoryURL.path)")
            } catch {
                print("Error creating directory: \(error)")
            }
        }
    }
}
