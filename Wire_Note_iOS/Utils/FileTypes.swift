import Foundation

struct FileTypes {
    static let audioExtensions = ["m4a", "mp3", "wav"]
    
    static func isAudioFile(url: URL) -> Bool {
        return audioExtensions.contains(url.pathExtension.lowercased())
    }
}
