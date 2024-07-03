import AVKit
import SwiftUI

extension VideoToMusicPages {
    struct CompositeVideoPage: View {
        @EnvironmentObject var videoToMusicData: VideoToMusicData

        @State private var wireDetectionWorker: WireDetectionWorker?
        @State private var videoAudioProcessor: VideoAudioProcessor?

        @State private var players: [AVPlayer] = []

        @State private var progress: Float = 0
        @State private var isProcessing = false

        @State private var loadingState: LoadingState?
        @State private var isDetectWire: Bool

        var wireDetectionOutputURL: URL {
            videoToMusicData.outputDirectoryURL.appendingPathComponent("wire_detection_output.mp4")
        }

        var outputDirectoryURL: URL {
            videoToMusicData.outputDirectoryURL.appendingPathComponent("CompositeVideoPage")
        }

        init(isDetectWire: Bool = true) {
            _isDetectWire = State(initialValue: isDetectWire)
        }

        var body: some View {
            VStack {
                if isProcessing {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                }

                ForEach(players.indices, id: \.self) { index in
                    VideoPlayer(player: players[index])
                        .frame(height: 300)
                        .onDisappear {
                            players[index].pause()
                        }
                }

                if let state = loadingState, state == .composite_video {
                    Text(state.description)
                }

                Toggle(isOn: $isDetectWire) {
                    Text("Detect Wire")
                }

                let isCreateCompositeVideoButtonDisable = loadingState != nil
                Button(action: {
                    Task {
                        loadingState = .composite_video
                        try await createCompositeVideo()
                    }
                }) {
                    Text("Create Composite Video Again")
                }
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isCreateCompositeVideoButtonDisable))
                .disabled(isCreateCompositeVideoButtonDisable)
            }
            .onAppear {
                Task {
                    loadingState = .composite_video
                    setupOutputDirectory()
                    try await createCompositeVideo()
                }
            }
        }

        private func setupOutputDirectory() {
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

        private func createCompositeVideo() async throws {
            print("CompositeVideoPage - createCompositeVideo")
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
                                try await addMusicToNewVideo()
                                loadingState = nil
                                self.progress = 1
                                self.isProcessing = false
                            }
                        } else {
                            self.progress = progress
                        }
                        if let error = error {
                            print("createCompositeVideo - processVideo - error: \(error)")
                            isProcessing = false
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
                                isProcessing = false
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

        private func loadVideoFiles() {
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
}

struct CompositeVideoPage_Previews: PreviewProvider {
    static var previews: some View {
        let testVideoUrl = Paths.projectRootPath.appendingPathComponent("Assets.xcassets/Videos/sky-1.dataset/sky-1.MOV")
        let testAudioUrl1 = Paths.projectRootPath.appendingPathComponent("Assets.xcassets/Audios/song-1.dataset/song-1.mp3")
        let testAudioUrl2 = Paths.projectRootPath.appendingPathComponent("Assets.xcassets/Audios/SpongeBob.dataset/SpongeBob.mp3")
        let videoToMusicData = VideoToMusicData()
        videoToMusicData.originVideoUrl = testVideoUrl
        videoToMusicData.downloadedGeneratedAudioUrls = [testAudioUrl1, testAudioUrl2]

        return VideoToMusicPages.CompositeVideoPage()
            .environmentObject(videoToMusicData)
    }
}
