import SwiftUI

extension VideoToMusicPages {
    struct GenerateMusicPage: View {
        static let pageTitle: String = "Generate Music"
        @EnvironmentObject var videoToMusicData: VideoToMusicData
        @StateObject private var viewModel: GenerateMusicViewModel

        @State private var style: String = ""
        @State private var title: String = ""
        @State private var isGenerateMusicButtonDisable = true
        @State private var isCompositeVideoDisable = true

        init(isMakeInstrumental: Bool = false) {
            _viewModel = StateObject(wrappedValue: GenerateMusicViewModel(videoToMusicData: nil, isMakeInstrumental: isMakeInstrumental))
        }

        var body: some View {
            VStack {
                Text("\(videoToMusicData.description.isEmpty ? "No description." : videoToMusicData.description)")

                generateMusicArea
                GeneratedAudioView(generatedAudioUrls: $videoToMusicData.generatedAudioUrls)

                toggleIsDetectWireButton
                navigateToCompositeVideoPageButton
            }
            .onAppear {
                updateIsGenerateMusicButtonDisable()
                if viewModel.videoToMusicData == nil {
                    viewModel.setVideoToMusicData(videoToMusicData)
                }
            }
            .onChange(of: viewModel.loadingState) {
                updateIsGenerateMusicButtonDisable()
                updateIsCompositeVideoDisable()
            }
            .onChange(of: videoToMusicData.downloadedGeneratedAudioUrls) {
                updateIsCompositeVideoDisable()
            }
            .navigationTitle(Self.pageTitle)
        }

        private func updateIsGenerateMusicButtonDisable() {
            isGenerateMusicButtonDisable = videoToMusicData.description.isEmpty || viewModel.loadingState == .generate_music
        }

        private func updateIsCompositeVideoDisable() {
            isCompositeVideoDisable = videoToMusicData.downloadedGeneratedAudioUrls.isEmpty || viewModel.loadingState != nil
        }

        private var generateMusicArea: some View {
            GenerateMusicArea(title: $title,
                              style: $style,
                              isGenerateMusicButtonDisable: $isGenerateMusicButtonDisable,
                              generatedAudioUrls: $videoToMusicData.generatedAudioUrls,
                              downloadedGeneratedAudioUrls: $videoToMusicData.downloadedGeneratedAudioUrls,
                              isMakeInstrumental: $viewModel.isMakeInstrumental,
                              loadingState: $viewModel.loadingState,
                              description: videoToMusicData.description,
                              generateMode: GenerateMode.customGenerate)
        }

        private var toggleIsDetectWireButton: some View {
            DetectWireButton(isDetectWire: $viewModel.isDetectWire)
                .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: isCompositeVideoDisable))
                .disabled(isCompositeVideoDisable)
                .padding()
        }

        private var navigateToCompositeVideoPageButton: some View {
            NavigationLink(destination: VideoToMusicPages.CompositeVideoPage(isDetectWire: viewModel.isDetectWire).environmentObject(videoToMusicData)) {
                Text(VideoToMusicPages.CompositeVideoPage.pageTitle)
            }
            .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: isCompositeVideoDisable))
            .disabled(isCompositeVideoDisable)
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
