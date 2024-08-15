import AVKit
import SwiftUI

extension VideoToMusicPages {
    struct CompositeVideoPage: View {
        @EnvironmentObject var videoToMusicData: VideoToMusicData
        @StateObject private var viewModel: CompositeVideoViewModel

        init(isDetectWire: Bool = true) {
            _viewModel = StateObject(wrappedValue: CompositeVideoViewModel(videoToMusicData: nil, isDetectWire: isDetectWire))
        }

        var body: some View {
            VStack {
                if viewModel.isProcessing {
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                }

                ForEach(viewModel.players.indices, id: \.self) { index in
                    VideoPlayer(player: viewModel.players[index])
                        .frame(height: 300)
                        .onDisappear {
                            viewModel.players[index].pause()
                        }
                }

                if let state = viewModel.loadingState, state == .composite_video {
                    Text(state.description)
                }

                Toggle(isOn: $viewModel.isDetectWire) {
                    Text("Detect Wire")
                }

                let isCreateCompositeVideoButtonDisable = viewModel.loadingState != nil
                Button(action: {
                    Task {
                        viewModel.loadingState = .composite_video
                        try await viewModel.createCompositeVideo()
                    }
                }) {
                    Text("Create Composite Video Again")
                }
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isCreateCompositeVideoButtonDisable))
                .disabled(isCreateCompositeVideoButtonDisable)
            }
            .onAppear {
                if viewModel.videoToMusicData == nil {
                    viewModel.setVideoToMusicData(videoToMusicData)
                }
                Task {
                    viewModel.loadingState = .composite_video
                    viewModel.setupOutputDirectory()
                    try await viewModel.createCompositeVideo()
                }
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
