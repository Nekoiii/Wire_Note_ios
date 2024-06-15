import AVKit
import SwiftUI

struct WireDetectionPage: View {
    @State private var worker: WireDetectionWorker?

    @State private var originVideoURL: URL?
    @State private var processedVideoURL: URL?

    @State private var originPlayer: AVPlayer?
    @State private var processedPlayer: AVPlayer?

    @State private var progress: Float = 0
    @State private var isProcessing = false

    @State private var isPickerPresented = false
    @State private var isVideoPlaying = false
    @State private var isShowingOriginVideo = true

    @State private var isShowingAlert = false
    @State private var errorMsg = ""
    @State private var alertTitle = "Error"

    var percentage: String {
        return String(format: "%.0f%%", progress * 100)
    }

    var isProcessButtonDisabled: Bool {
        return originVideoURL == nil || isProcessing
    }

    var outputURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("output.mp4")
    }

    var body: some View {
        ScrollView {
            VStack {
//                    Text("originVideoURL: \(originVideoURL?.absoluteString ?? "")")
//                    Text("processedVideoURL: \(processedVideoURL?.absoluteString ?? "")")
                
                if processedVideoURL != nil {
                    Button(action: {}) {
                        Text("Show Origin Video")
                            .font(.system(size: 15))
                    }
                    .buttonStyle(SolidButtonStyle(buttonColor: Color("AccentColor")))
                    .onLongPressGesture(minimumDuration: 0.1, pressing: { isPressing in
                        isShowingOriginVideo = isPressing
                        originPlayer?.isMuted = !isPressing
                    }, perform: {})
                }

                ZStack {
                    // Only show origin video when there is no processed video or pressing the ShowOriginVideo button.
                    VideoPlayer(player: originPlayer)
                        .frame(height: 300)
                        .opacity(isShowingOriginVideo ? 1 : 0)
                        .onAppear {
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: originPlayer?.currentItem,
                                queue: .main
                            ) { _ in
                                togglePlayback()
                                originPlayer?.seek(to: .zero)
                                print("Video finished playing.")
                            }
                        }

                    // Show processed video above the original video.
                    if let processedPlayer = processedPlayer {
                        VideoPlayer(player: processedPlayer)
                            .frame(height: 300)
                            .opacity(isShowingOriginVideo ? 0 : 1)
                    }
                }

                if originPlayer != nil || processedVideoURL != nil {
                    Button(action: {
                        togglePlayback()
                    }) {
                        Image(systemName: isVideoPlaying ? "pause.circle" : "play.circle")
                            .resizable()
                            .frame(width: 50, height: 50)
                    }
                }

                HStack {
                    Button {
                        isPickerPresented.toggle()
                    } label: {
                        Label("Select Video", systemImage: "video")
                    }
                    .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: isProcessing))
                    .disabled(isProcessing)

                    Button {
                        processVideo()
                    } label: {
                        Label("Process Video", systemImage: "play.fill")
                    }
                    .buttonStyle(BorderedButtonStyle(borderColor: .green, isDisable: isProcessButtonDisabled))
                    .disabled(isProcessButtonDisabled)
                }
                .padding(.vertical, 10)

                if progress == 1 {
                    Divider()
                    VStack {
                        Text("🎉 Video processed successfully 🎉")
                            .font(.title3)
                        HStack {
                            ShareLink(item: outputURL)
                                .buttonStyle(BorderedButtonStyle(borderColor: .blue, isDisable: isProcessButtonDisabled))
                                .disabled(isProcessButtonDisabled)
                        }
                    }
                    .padding(.top, 10)
                    .transition(.scale)
                }

                if isProcessing {
                    VStack {
                        HStack {
                            Text("Video is processing...(\(percentage))")
                            Spacer()
                            Button {
                                worker?.cancelProcessing()
                                isProcessing = false
                            } label: {
                                Text("Cancel")
                                    .foregroundColor(.red)
                            }
                        }
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Wire Detection")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPickerPresented, onDismiss: setupOriginPlayers) {
            VideoPicker(videoURL: $originVideoURL)
        }
        .alert(alertTitle, isPresented: $isShowingAlert) {
            Button(role: .cancel) {
                isShowingAlert = false
            } label: {
                Text("OK")
            }
        } message: {
            Text(errorMsg)
        }
    }

    private func togglePlayback() {
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

    private func setupOriginPlayers() {
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

    func processVideo() {
        isProcessing = true
        progress = 0
        Task {
            do {
                guard let url = originVideoURL
                else {
                    throw WireDetectionError.invalidURL
                }
                self.worker = try await WireDetectionWorker(inputURL: url, outputURL: outputURL)
                try await worker?.processVideo(url: url) { progress, error in
                    DispatchQueue.main.async {
                        if progress == 1 {
                            processedVideoURL = outputURL
                            setupProcessedPlayer()
                            originPlayer?.pause()
                            processedPlayer?.pause()
                            isVideoPlaying = false
                            originPlayer?.seek(to: .zero)
                            withAnimation {
                                self.progress = progress
                                self.isProcessing = false
                            }
                        } else {
                            self.progress = progress
                        }
                        if let error = error {
                            alertTitle = "Error"
                            isShowingAlert = true
                            errorMsg = error.localizedDescription
                            isProcessing = false
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isShowingAlert = true
                    errorMsg = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WireDetectionPage()
    }
}
