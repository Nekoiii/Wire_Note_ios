import AVKit
import SwiftUI

class UploadVideoViewModel: ObservableObject {
    @EnvironmentObject private var videoToMusicData: VideoToMusicData

    @Published var videoPlayer: AVPlayer?

    @Published var isPickerPresented = false
    @Published var loadingState: LoadingState?

    func setupVideoPlayer() {
        DispatchQueue.main.async {
            if let url = self.videoToMusicData.originVideoUrl {
                self.videoPlayer = AVPlayer(url: url)
                print("setupVideoPlayer: \(String(describing: self.videoPlayer))")
            }
        }
    }
}
