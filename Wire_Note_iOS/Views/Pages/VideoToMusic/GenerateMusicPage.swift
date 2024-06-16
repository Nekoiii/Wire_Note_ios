import SwiftUI

extension VideoToMusicPages {
    struct GenerateMusicPage: View {
        @EnvironmentObject var videoToMusicData: VideoToMusicData

        @State private var loadingState: LoadingState?

        @State private var isMakeInstrumental: Bool
        @State private var isDetectWire: Bool = true

        init(isMakeInstrumental: Bool = false) {
            _isMakeInstrumental = State(initialValue: isMakeInstrumental)
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

                let isCompositeVideoDisable = loadingState != nil || videoToMusicData.downloadedGeneratedAudioUrls.isEmpty
                VStack {
                    NavigationLink(destination: VideoToMusicPages.CompositeVideoPage(isDetectWire: isDetectWire).environmentObject(videoToMusicData)) {
                        Text("-> Composite Video")
                    }
                    Toggle(isOn: $isDetectWire) {
                        Text("Detect Wire")
                    }
                }
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isCompositeVideoDisable))
                .disabled(isCompositeVideoDisable)
            }
            .onAppear {
                Task {
                    loadingState = .generate_music
                    await generateMusicWithDescription()
                    loadingState = nil
                }
            }
        }

        // *unfinished: need to be refactor with same function in ImageToMusicPage.swift
        private var generateMusicArea: some View {
            Group {
                if let state = loadingState, state == .generate_music || state == .download_file {
                    Text(state.description)
                }

                let isGenerateMusicButtonDisable = videoToMusicData.description.isEmpty || loadingState != nil
                Button(action: {
                    Task {
                        loadingState = .generate_music
                        await generateMusicWithDescription()
                        loadingState = nil
                    }
                }) {
                    Text("Generate Music Again")
                }
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isGenerateMusicButtonDisable))
                .disabled(isGenerateMusicButtonDisable)

                InstrumentalToggleView(isMakeInstrumental: $isMakeInstrumental)
                    .padding()
            }
        }

        private func generateMusicWithDescription() async {
            let generatePrompt = videoToMusicData.description
            let generateIsMakeInstrumental = isMakeInstrumental
            let generateMode = GenerateMode.generate

            let sunoGenerateAPI = SunoGenerateAPI(generateMode: generateMode)

            let audioUrls = await sunoGenerateAPI.generatemMusic(generateMode: generateMode, prompt: generatePrompt, makeInstrumental: generateIsMakeInstrumental)
            videoToMusicData.generatedAudioUrls = audioUrls
            Task {
                loadingState = .download_file
                videoToMusicData.downloadedGeneratedAudioUrls = await sunoGenerateAPI.downloadAndSaveFiles(audioUrls: audioUrls)
                loadingState = nil
            }
        }
    }
}
