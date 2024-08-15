import SwiftUI

extension VideoToMusicPages {
    struct GenerateMusicPage: View {
        @EnvironmentObject var videoToMusicData: VideoToMusicData
        @StateObject private var viewModel: GenerateMusicViewModel

        init(isMakeInstrumental: Bool = false) {
            _viewModel = StateObject(wrappedValue: GenerateMusicViewModel(videoToMusicData: nil, isMakeInstrumental: isMakeInstrumental))
        }

        var body: some View {
            VStack {
                if !videoToMusicData.description.isEmpty {
                    Text("Description: \(videoToMusicData.description)")
                } else {
                    Text("No description.")
                }

                generateMusicArea

                GeneratedAudioView(generatedAudioUrls: $videoToMusicData.generatedAudioUrls)

                let isCompositeVideoDisable = viewModel.loadingState != nil || videoToMusicData.downloadedGeneratedAudioUrls.isEmpty
                VStack {
                    NavigationLink(destination: VideoToMusicPages.CompositeVideoPage(isDetectWire: viewModel.isDetectWire).environmentObject(videoToMusicData)) {
                        Text("-> Composite Video")
                    }
                    Toggle(isOn: $viewModel.isDetectWire) {
                        Text("Detect Wire")
                    }
                }
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isCompositeVideoDisable))
                .disabled(isCompositeVideoDisable)
            }
            .onAppear {
                if viewModel.videoToMusicData == nil {
                    viewModel.setVideoToMusicData(videoToMusicData)
                }
                Task {
                    viewModel.loadingState = .generate_music
                    await viewModel.generateMusicWithDescription()
                    viewModel.loadingState = nil
                }
            }
        }

        // *unfinished: need to be refactor with same function in ImageToMusicPage.swift
        private var generateMusicArea: some View {
            Group {
                if let state = viewModel.loadingState, state == .generate_music || state == .download_file {
                    Text(state.description)
                }

                let isGenerateMusicButtonDisable = videoToMusicData.description.isEmpty || viewModel.loadingState != nil
                Button(action: {
                    Task {
                        viewModel.loadingState = .generate_music
                        await viewModel.generateMusicWithDescription()
                        viewModel.loadingState = nil
                    }
                }) {
                    Text("Generate Music Again")
                }
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isGenerateMusicButtonDisable))
                .disabled(isGenerateMusicButtonDisable)

                InstrumentalToggleView(isMakeInstrumental: $viewModel.isMakeInstrumental)
                    .padding()
            }
        }
    }
}
