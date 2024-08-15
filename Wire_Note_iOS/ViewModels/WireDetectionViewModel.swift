import AVKit
import Combine
import SwiftUI

class WireDetectionViewModel: ObservableObject {
    @Published var worker: WireDetectionWorker?
    @Published var videoAudioProcessor: VideoAudioProcessor?

    @Published var originVideoURL: URL?
    @Published var processedVideoURL: URL?

    @Published var originPlayer: AVPlayer?
    @Published var processedPlayer: AVPlayer?

    @Published var progress: Float = 0
    @Published var isProcessing = false

    @Published var isPickerPresented = false
    @Published var isVideoPlaying = false
    @Published var isShowingOriginVideo = true

    @Published var isShowingAlert = false
    @Published var errorMsg = ""
    @Published var alertTitle = "Error"

    var percentage: String {
        return String(format: "%.0f%%", progress * 100)
    }

    var outputURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("output.mp4")
    }

    func processVideo() {
        isProcessing = true
        progress = 0
        Task {
            do {
                guard let url = originVideoURL else {
                    throw WireDetectionError.invalidURL
                }
                self.worker = try await WireDetectionWorker(inputURL: url, outputURL: outputURL)
                worker?.processVideo(url: url) { progress, error in
                    DispatchQueue.main.async {
                        if progress == 1 {
                            withAnimation {
                                self.progress = progress
                                self.isProcessing = false
                            }

                            Task {
                                await self.addAudioToNewVideo()

                                self.progress = 1
                                self.isProcessing = false

                                self.processedVideoURL = self.outputURL
                                self.setupProcessedPlayer()
                                self.originPlayer?.pause()
                                self.processedPlayer?.pause()
                                self.isVideoPlaying = false
                                await self.originPlayer?.seek(to: .zero)
                            }

                        } else {
                            self.progress = progress
                        }
                        if let error = error {
                            self.alertTitle = "Error"
                            self.isShowingAlert = true
                            self.errorMsg = error.localizedDescription
                            self.isProcessing = false
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isShowingAlert = true
                    self.errorMsg = error.localizedDescription
                }
            }
        }
    }

    func togglePlayback() {
        if isVideoPlaying {
            originPlayer?.pause()
            processedPlayer?.pause()
        } else {
            // Synchronize the original video playback time with the processed video
            if let currentTime = originPlayer?.currentTime() {
                processedPlayer?.seek(to: currentTime)
            }
            originPlayer?.play()
            processedPlayer?.play()
        }

        isVideoPlaying.toggle()
    }
    
    func setupOriginPlayers() {
        if let url = originVideoURL {
            processedPlayer = nil
            processedVideoURL = nil
            originPlayer = AVPlayer(url: url)
            print("setupOriginPlayers: \(String(describing: originPlayer))")
        }
    }
    
    private func setupProcessedPlayer() {
        print("setupProcessedPlayer - \(String(describing: processedVideoURL))")
        if let url = processedVideoURL {
            processedPlayer = AVPlayer(url: url)
            isShowingOriginVideo = false
            originPlayer?.isMuted = true
        }
    }

    private func addAudioToNewVideo() async {
        isProcessing = true
        progress = 0
        do {
            let extractedAudioURL = outputURL.deletingLastPathComponent().appendingPathComponent("extracted_audio.m4a")
            let tempOutputVideoUrl = outputURL.deletingLastPathComponent().appendingPathComponent("temp_output_video.m4a")

            guard let originVideoURL = originVideoURL else {
                print("no originVideoURL")
                return
            }
            videoAudioProcessor = VideoAudioProcessor()

            try await videoAudioProcessor?.extractAndAddAudioToVideo(originVideoURL: originVideoURL, extractedAudioURL: extractedAudioURL, videoURL: outputURL, outputVideoURL: tempOutputVideoUrl) { progress, error in
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
                        print("addAudioToNewVideo - extractAndAddAudioToVideo - error: \(error)")
                        self.isProcessing = false
                    }
                }
            }

            // replace audio in outputURL with audio in tempOutputVideoUrl
            removeExistingFile(at: outputURL)
            try FileManager.default.moveItem(at: tempOutputVideoUrl, to: outputURL)
            progress = 1
            isProcessing = false
        } catch {
            print("addAudioToNewVideo - error : \(error)")
        }
    }
}
