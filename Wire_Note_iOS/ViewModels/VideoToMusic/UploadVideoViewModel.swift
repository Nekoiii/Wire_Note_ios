import AVKit
import SwiftUI

class UploadVideoViewModel: ObservableObject {
    @Published var videoPlayer: AVPlayer?

    @Published var isPickerPresented = false
    @Published var loadingState: LoadingState?

    private var videoToMusicData: VideoToMusicData

    init(videoToMusicData: VideoToMusicData) {
        self.videoToMusicData = videoToMusicData
    }

    func setupVideoPlayer() {
        DispatchQueue.main.async {
            if let url = self.videoToMusicData.originVideoUrl {
                self.videoPlayer = AVPlayer(url: url)
                print("setupVideoPlayer: \(String(describing: self.videoPlayer))")
            }
        }
    }
}
