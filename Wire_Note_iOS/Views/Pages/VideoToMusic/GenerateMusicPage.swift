import SwiftUI

extension VideoToMusicPages {
    struct GenerateMusicPage: View {
        static let pageTitle: String = "Generate Music"
        @EnvironmentObject var videoToMusicData: VideoToMusicData
        @StateObject private var viewModel: GenerateMusicViewModel

        @State private var style: String = ""
        @State private var title: String = ""
        @State private var isGenerateMusicButtonDisable = true

        init(isMakeInstrumental: Bool = false) {
            _viewModel = StateObject(wrappedValue: GenerateMusicViewModel(videoToMusicData: nil, isMakeInstrumental: isMakeInstrumental))
        }

        var body: some View {
            VStack {
                Text("\(videoToMusicData.description.isEmpty ? "No description." : videoToMusicData.description)")

                generateMusicArea

                GeneratedAudioView(generatedAudioUrls: $videoToMusicData.generatedAudioUrls)

                let isCompositeVideoDisable = viewModel.loadingState != nil || videoToMusicData.downloadedGeneratedAudioUrls.isEmpty
                VStack {
                    NavigationLink(destination: VideoToMusicPages.CompositeVideoPage(isDetectWire: viewModel.isDetectWire).environmentObject(videoToMusicData)) {
                        Text(VideoToMusicPages.CompositeVideoPage.pageTitle)
                    }
                    Toggle(isOn: $viewModel.isDetectWire) {
                        Text("Detect Wire")
                    }
                }
                .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: isCompositeVideoDisable))
                .disabled(isCompositeVideoDisable)
            }
            .onAppear {
                updateGenerateMusicButtonState()
                if viewModel.videoToMusicData == nil {
                    viewModel.setVideoToMusicData(videoToMusicData)
                }
            }
            .onChange(of: viewModel.loadingState) {
                updateGenerateMusicButtonState()
            }
            .navigationTitle(Self.pageTitle)
        }

        private func updateGenerateMusicButtonState() {
            isGenerateMusicButtonDisable = videoToMusicData.description.isEmpty || viewModel.loadingState == .generate_music
        }

        private var generateMusicArea: some View {
            VStack {
                if let state = viewModel.loadingState, state == .generate_music || state == .download_file {
                    Text(state.description)
                } else {
                    Text(" ")
                }

                GenerateMusicArea(title: $title,
                                  style: $style,
                                  isGenerateMusicButtonDisable: $isGenerateMusicButtonDisable,
                                  generatedAudioUrls: $videoToMusicData.generatedAudioUrls,
                                  isMakeInstrumental: $viewModel.isMakeInstrumental,
                                  loadingState: $viewModel.loadingState,
                                  description: videoToMusicData.description,
                                  generateMode: GenerateMode.customGenerate)
            }
        }
    }
}

struct GenerateMusicPage_ExtractAndDescribeFramesPage_Previews: PreviewProvider {
    @StateObject private static var videoToMusicData = VideoToMusicData()
    static var previews: some View {
        VideoToMusicPages.GenerateMusicPage()
            .environmentObject(videoToMusicData)
    }
}
