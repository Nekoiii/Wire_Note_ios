import AVKit
import SwiftUI

class UploadVideoViewModel: BaseViewModel {
    @Published var videoPlayer: AVPlayer?
    @Published var isPickerPresented = false

    private(set) var videoToMusicData: VideoToMusicData?

    init(videoToMusicData: VideoToMusicData?) {
        self.videoToMusicData = videoToMusicData
    }

    func setVideoToMusicData(_ videoToMusicData: VideoToMusicData) {
        self.videoToMusicData = videoToMusicData
    }

    func setupVideoPlayer() {
        guard let videoToMusicData = videoToMusicData else { return }
        DispatchQueue.main.async {
            if let url = videoToMusicData.originVideoUrl {
                self.videoPlayer = AVPlayer(url: url)
                print("setupVideoPlayer: \(String(describing: self.videoPlayer))")
            }
        }
    }
}
