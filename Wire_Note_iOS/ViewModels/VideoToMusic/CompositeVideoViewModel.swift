import AVKit
import SwiftUI

class CompositeVideoViewModel: ObservableObject {
    @Published var wireDetectionWorker: WireDetectionWorker?
    @Published var videoAudioProcessor: VideoAudioProcessor?
    @Published var players: [AVPlayer] = []

    @Published var progress: Float = 0
    @Published var isProcessing = false
    @Published var loadingState: LoadingState?
    @Published var isDetectWire: Bool

    private(set) var videoToMusicData: VideoToMusicData?

    init(videoToMusicData: VideoToMusicData?, isDetectWire: Bool = true) {
        self.videoToMusicData = videoToMusicData
        self.isDetectWire = isDetectWire
    }

    func setVideoToMusicData(_ videoToMusicData: VideoToMusicData) {
        self.videoToMusicData = videoToMusicData
    }

    var wireDetectionOutputURL: URL? {
        videoToMusicData?.outputDirectoryURL.appendingPathComponent("wire_detection_output.mp4")
    }

    var outputDirectoryURL: URL? {
        videoToMusicData?.outputDirectoryURL.appendingPathComponent("CompositeVideoPage")
    }

    func setupOutputDirectory() {
        guard let outputDirectoryURL = outputDirectoryURL else { return }
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: outputDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                print("Directory created at: \(outputDirectoryURL.path)")
            } catch {
                loadingState = nil
                print("Error creating directory: \(error)")
            }
        }
    }

    func clearOutputDirectory() {
        guard let outputDirectoryURL = outputDirectoryURL else { return }
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: outputDirectoryURL, includingPropertiesForKeys: nil, options: [])
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
            print("All files in CompositeVideoPage deleted successfully.")
        } catch {
            print("Error deleting files: \(error)")
        }
    }

    func createCompositeVideo() async throws {
        print("CompositeVideoPage - createCompositeVideo")
        guard let videoToMusicData = videoToMusicData else { return }

        guard let wireDetectionOutputURL = wireDetectionOutputURL else { return }

        isProcessing = true
        progress = 0
        clearOutputDirectory()
        do {
            guard let originVideoUrl = videoToMusicData.originVideoUrl
            else {
                throw WireDetectionError.invalidURL
            }
            wireDetectionWorker = try await WireDetectionWorker(inputURL: originVideoUrl, outputURL: wireDetectionOutputURL)
            wireDetectionWorker?.processVideo(url: originVideoUrl) { progress, error in
                DispatchQueue.main.async {
                    if progress == 1 {
                        withAnimation {
                            self.progress = progress
                            self.isProcessing = false
                        }
                        Task {
                            try await self.addMusicToNewVideo()
                            self.loadingState = nil
                            self.progress = 1
                            self.isProcessing = false
                        }
                    } else {
                        self.progress = progress
                    }
                    if let error = error {
                        print("createCompositeVideo - processVideo - error: \(error)")
                        self.isProcessing = false
                    }
                }
            }
        } catch {
            loadingState = nil
            print("createCompositeVideo - error: \(error)")
        }
    }

    private func addMusicToNewVideo() async throws {
        print("CompositeVideoPage - addMusicToNewVideo")
        guard let videoToMusicData = videoToMusicData else { return }
        guard let outputDirectoryURL = outputDirectoryURL else { return }
        guard let wireDetectionOutputURL = wireDetectionOutputURL else { return }
        do {
            for (index, url) in videoToMusicData.downloadedGeneratedAudioUrls.enumerated() {
                print("addMusicToNewVideo - Index: \(index), URL: \(url)")
                isProcessing = true
                progress = 0

                let outputVideoUrl = outputDirectoryURL.appendingPathComponent("output_\(index).mp4")

                videoAudioProcessor = VideoAudioProcessor()

                try await videoAudioProcessor?.addAudioToVideo(videoURL: wireDetectionOutputURL, audioURL: url, outputURL: outputVideoUrl) { progress, error in
                    DispatchQueue.main.async {
                        if progress == 1 {
                            withAnimation {
                                self.progress = progress
                                self.isProcessing = false
                            }
                        } else {
                            self.progress = progress
                        }
                        if let error = error {
                            print("addMusicToNewVideo - addAudioToVideo - error: \(error)")
                            self.isProcessing = false
                        }
                    }
                }
            }
            loadVideoFiles()
        } catch {
            loadingState = nil
            isProcessing = false
            progress = 1
            print("addMusicToNewVideo error: \(error)")
        }
    }

    func loadVideoFiles() {
        guard let outputDirectoryURL = outputDirectoryURL else { return }
        do {
            let videoFiles = try FileManager.default.contentsOfDirectory(at: outputDirectoryURL, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "mp4" }

            players = videoFiles.map { AVPlayer(url: $0) }
        } catch {
            loadingState = nil
            print("Error loading video files: \(error)")
        }
    }
}
