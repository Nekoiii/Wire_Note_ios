import AVFoundation

class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()

    @Published private(set) var isPlaying = false
    private var currentUrl: URL?
    private var player: AVPlayer?

    private init() {}

    func play(url: URL) {
        if isCurrentPlayingUrl(url) {
            togglePlayPause()
        } else {
            pause()
            player = AVPlayer(url: url)
            currentUrl = url
            player?.play()
            isPlaying = true
        }
    }

    func pause() {
        player?.pause()
        player = nil
        currentUrl = nil
        isPlaying = false
    }

    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }

    func isCurrentPlayingUrl(_ url: URL) -> Bool {
        return currentUrl == url
    }
}
