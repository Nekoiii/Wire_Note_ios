import AVKit
import SwiftUI

struct WireDetectionPage: View {
    @StateObject private var viewModel = WireDetectionViewModel()

    var isProcessButtonDisabled: Bool {
        return viewModel.originVideoURL == nil || viewModel.isProcessing
    }

    var body: some View {
        ScrollView {
            VStack {
                if viewModel.processedVideoURL != nil {
                    Button(action: {}) {
                        Text("Show Origin Video")
                            .font(.system(size: 15))
                    }
                    .buttonStyle(SolidButtonStyle(buttonColor: Color("AccentColor")))
                    .onLongPressGesture(minimumDuration: 0.1, pressing: { isPressing in
                        viewModel.isShowingOriginVideo = isPressing
                        viewModel.originPlayer?.isMuted = !isPressing
                    }, perform: {})
                }

                ZStack {
                    // Only show origin video when there is no processed video or pressing the ShowOriginVideo button.
                    VideoPlayer(player: viewModel.originPlayer)
                        .frame(height: 300)
                        .opacity(viewModel.isShowingOriginVideo ? 1 : 0)
                        .onAppear {
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: viewModel.originPlayer?.currentItem,
                                queue: .main
                            ) { _ in
                                viewModel.togglePlayback()
                                viewModel.originPlayer?.seek(to: .zero)
                                print("Video finished playing.")
                            }
                        }

                    // Show processed video above the original video.
                    if let processedPlayer = viewModel.processedPlayer {
                        VideoPlayer(player: processedPlayer)
                            .frame(height: 300)
                            .opacity(viewModel.isShowingOriginVideo ? 0 : 1)
                    }
                }

                if viewModel.originPlayer != nil || viewModel.processedVideoURL != nil {
                    Button(action: {
                        viewModel.togglePlayback()
                    }) {
                        Image(systemName: viewModel.isVideoPlaying ? "pause.circle" : "play.circle")
                            .resizable()
                            .frame(width: 50, height: 50)
                    }
                }

                HStack {
                    Button {
                        viewModel.isPickerPresented.toggle()
                    } label: {
                        Label("Select Video", systemImage: "video")
                    }
                    .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: viewModel.isProcessing))
                    .disabled(viewModel.isProcessing)

                    Button {
                        viewModel.processVideo()
                    } label: {
                        Label("Process Video", systemImage: "play.fill")
                    }
                    .buttonStyle(BorderedButtonStyle(borderColor: .green, isDisable: isProcessButtonDisabled))
                    .disabled(isProcessButtonDisabled)
                }
                .padding(.vertical, 10)

                if viewModel.progress == 1 {
                    Divider()
                    VStack {
                        Text("🎉 Video processed successfully 🎉")
                            .font(.title3)
                        HStack {
                            ShareLink(item: viewModel.outputURL)
                                .buttonStyle(BorderedButtonStyle(borderColor: .blue, isDisable: isProcessButtonDisabled))
                                .disabled(isProcessButtonDisabled)
                        }
                    }
                    .padding(.top, 10)
                    .transition(.scale)
                }

                if viewModel.isProcessing {
                    VStack {
                        HStack {
                            Text("Video is processing...(\(viewModel.percentage))")
                            Spacer()
                            Button {
                                viewModel.worker?.cancelProcessing()
                                viewModel.isProcessing = false
                            } label: {
                                Text("Cancel")
                                    .foregroundColor(.red)
                            }
                        }
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Wire Detection")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.isPickerPresented, onDismiss: viewModel.setupOriginPlayers) {
            VideoPicker(videoURL: $viewModel.originVideoURL)
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.isShowingAlert) {
            Button(role: .cancel) {
                viewModel.isShowingAlert = false
            } label: {
                Text("Finished!")
            }
        } message: {
            Text(viewModel.errorMsg)
        }
        .onAppear {
            if Constants.debugMode {}
        }
    }
}

#Preview {
    NavigationStack {
        WireDetectionPage()
    }
}
