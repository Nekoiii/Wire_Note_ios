import AVKit
import SwiftUI

class CompositeVideoViewModel: BaseViewModel {
    @Published var wireDetectionWorker: WireDetectionWorker?
    @Published var videoAudioProcessor: VideoAudioProcessor?
    @Published var players: [AVPlayer] = []

    @Published var progress: Float = 0
//    @Published var isProcessing = false
    @Published var isDetectWire: Bool

    private(set) var videoToMusicData: VideoToMusicData?

    var wireDetectionOutputURL: URL? {
        videoToMusicData?.outputDirectoryURL.appendingPathComponent("wire_detection_output.mp4")
    }

    var outputDirectoryURL: URL? {
        videoToMusicData?.outputDirectoryURL.appendingPathComponent("CompositeVideoPage")
    }

    init(videoToMusicData: VideoToMusicData?, isDetectWire: Bool = true) {
        self.videoToMusicData = videoToMusicData
        self.isDetectWire = isDetectWire
    }

    func initializeViewModel(_ videoToMusicData: VideoToMusicData) {
        guard self.videoToMusicData == nil else { return }

        self.videoToMusicData = videoToMusicData
    }

    func doCreateCompositeVideo() async throws {
        loadingState = .composite_video
        try await createCompositeVideo()
//        loadingState = nil
    }

    func createCompositeVideo() async throws {
        print("CompositeVideoPage - createCompositeVideo")
        guard
            let videoToMusicData = videoToMusicData,
            let wireDetectionOutputURL = wireDetectionOutputURL
        else { return }

        progress = 0
        setupOutputDirectory()
        clearOutputDirectory()

        do {
            guard let originVideoUrl = videoToMusicData.originVideoUrl else {
                throw WireDetectionError.invalidURL
            }
            wireDetectionWorker = try await WireDetectionWorker(inputURL: originVideoUrl, outputURL: wireDetectionOutputURL)
            wireDetectionWorker?.processVideo(url: originVideoUrl) { progress, error in
                DispatchQueue.main.async {
                    if progress >= 1 {
                        self.progress = 1
                        Task {
                            self.progress = 0
                            try await self.addMusicToNewVideo()
                        }
                    } else {
                        self.progress = progress
                    }
                    if let error = error {
                        print("createCompositeVideo - processVideo - error: \(error)")
                    }
                }
            }

        } catch {
            print("createCompositeVideo - error: \(error)")
            loadingState = nil
        }
    }

    func setupOutputDirectory() {
        guard let outputDirectoryURL = outputDirectoryURL else { return }
        guard createDirectoryIfNotExists(at: outputDirectoryURL) else { return }
    }

    func clearOutputDirectory() {
        guard let outputDirectoryURL = outputDirectoryURL else { return }
        guard removeAllFilesInDirectory(at: outputDirectoryURL) else { return }
    }

    private func addMusicToNewVideo() async throws {
        print("CompositeVideoPage - addMusicToNewVideo")

        guard
            let videoToMusicData = videoToMusicData,
            let outputDirectoryURL = outputDirectoryURL,
            let wireDetectionOutputURL = wireDetectionOutputURL
        else { return }

        do {
            for (index, url) in videoToMusicData.downloadedGeneratedAudioUrls.enumerated() {
                print("addMusicToNewVideo - Index: \(index), URL: \(url)")

                let outputVideoUrl = outputDirectoryURL.appendingPathComponent("output_\(index).mp4")

                videoAudioProcessor = VideoAudioProcessor()

                try await videoAudioProcessor?.addAudioToVideo(videoURL: wireDetectionOutputURL, audioURL: url, outputURL: outputVideoUrl) { progress, error in
                    DispatchQueue.main.async {
                        if progress >= 1 {
                            self.progress = 1
                            self.loadingState = nil
                        } else {
                            self.progress = progress
                        }
                        if let error = error {
                            print("addMusicToNewVideo - addAudioToVideo - error: \(error)")
                        }
                    }
                }
            }
            loadVideoFiles()
        } catch {
            print("addMusicToNewVideo -- error: \(error)")
            loadingState = nil
        }
    }

    func loadVideoFiles() {
        loadingState = nil
        guard let outputDirectoryURL = outputDirectoryURL else { return }
        do {
            let videoFiles = try FileManager.default.contentsOfDirectory(at: outputDirectoryURL, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "mp4" }

            players = videoFiles.map { AVPlayer(url: $0) }
            loadingState = nil
        } catch {
            print("loadVideoFiles - error: \(error)")
            loadingState = nil
        }
    }
}
