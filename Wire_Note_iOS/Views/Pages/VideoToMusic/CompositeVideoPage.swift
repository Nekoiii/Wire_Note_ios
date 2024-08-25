import AVKit
import SwiftUI

extension VideoToMusicPages {
    struct CompositeVideoPage: View {
        static let pageTitle: String = "Composite Video"
        @EnvironmentObject var videoToMusicData: VideoToMusicData
        @StateObject private var viewModel: CompositeVideoViewModel

        init(isDetectWire: Bool = true) {
            _viewModel = StateObject(wrappedValue: CompositeVideoViewModel(videoToMusicData: nil, isDetectWire: isDetectWire))
        }

        var body: some View {
            VStack {
                Text(String(format: "%.1f %%", viewModel.progress * 100))
                viewModel.loadingState == .composite_video ? ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle()) : nil

                videosArea

                Text(viewModel.loadingState == .composite_video || viewModel.loadingState == .load ? viewModel.loadingState?.description ?? " " : " ")

                DetectWireButton(isDetectWire: $viewModel.isDetectWire)
                createCompositeVideoButton
            }
            .padding()
            .onAppear {
                viewModel.initializeViewModel(videoToMusicData)

                Task {
                    try await viewModel.doCreateCompositeVideo()
                }
            }
            .navigationTitle(Self.pageTitle)
        }

        private var videosArea: some View {
            VStack {
                ForEach(viewModel.players.indices, id: \.self) { index in
                    VideoPlayer(player: viewModel.players[index])
                        .frame(height: 300)
                        .onDisappear {
                            viewModel.players[index].pause()
                        }
                }
            }
        }

        private var createCompositeVideoButton: some View {
            let isButtonDisable = viewModel.loadingState != nil
            return Button(action: {
                Task { try await viewModel.doCreateCompositeVideo() }
            }) {
                Text("Create Composite Video Again")
            }
            .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: isButtonDisable))
            .disabled(isButtonDisable)
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
