import AVKit
import SwiftUI

class ExtractAndDescribeFramesViewModel: ObservableObject {
    @Published var extractedFrames: [UIImage] = []
    @Published var selectedImage: UIImage? = nil

    @Published var isImageViewerPresented = false
    @Published var isMakeInstrumental: Bool = false
    @Published var loadingState: LoadingState?

    private(set) var videoToMusicData: VideoToMusicData?

    init(videoToMusicData: VideoToMusicData?) {
        self.videoToMusicData = videoToMusicData
    }

    func setVideoToMusicData(_ videoToMusicData: VideoToMusicData) {
        self.videoToMusicData = videoToMusicData
    }

    func doExtractRandomFrames() {
        guard let videoUrl = videoToMusicData?.originVideoUrl else {
            print("Video URL is nil")
            return
        }
        videoToMusicData?.description = ""
        loadingState = .extract_frames
        extractRandomFrames(from: videoUrl, frameCount: 6) { extractedFrames in
            self.extractedFrames = extractedFrames
            self.loadingState = nil
        }
    }

    func describeFrames() {
        guard let videoToMusicData = videoToMusicData else { return }
        loadingState = .image_to_text

        for image in extractedFrames {
            guard let imageData = image.pngData() else {
                print("describeFrames - no imageData")
                return
            }

            imageToText(imageData: imageData) { result in
                switch result {
                case let .success(desc):
                    DispatchQueue.main.async {
                        if videoToMusicData.description.isEmpty {
                            videoToMusicData.description += desc
                        } else {
                            videoToMusicData.description += ". " + desc
                        }
                    }
                case let .failure(error):
                    DispatchQueue.main.async {
                        print("describeFrames - error: \(error.localizedDescription)")
                    }
                }
                self.loadingState = nil

                if videoToMusicData.description.count > 150 { // *unfinished
                    videoToMusicData.description = String(videoToMusicData.description.prefix(150))
                }
            }
        }
    }
}
