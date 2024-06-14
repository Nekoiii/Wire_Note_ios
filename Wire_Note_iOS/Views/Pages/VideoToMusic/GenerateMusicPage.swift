import SwiftUI


extension VideoToMusicPages {
    struct GenerateMusicPage: View {
        @EnvironmentObject var videoToMusicData: VideoToMusicData

        
        @State private var loadingState: LoadingState?
        
        @State private var isMakeInstrumental: Bool
        
        init(isMakeInstrumental: Bool = false) {
            self._isMakeInstrumental = State(initialValue: isMakeInstrumental)
        }
        
        var body: some View {
            VStack{
                if !videoToMusicData.description.isEmpty {
                    Text("Description: \(videoToMusicData.description)")
                }else{
                    Text("No description.")
                }
                
                generateMusicArea
                
                GeneratedAudioView(generatedAudioUrls: $videoToMusicData.generatedAudioUrls)
                
                let isDGeneratedAudiosNil = videoToMusicData.description.isEmpty
                NavigationLink(destination: VideoToMusicPages.CompositeVideoPage().environmentObject(videoToMusicData)){
                    Text("-> Composite Video")
                }
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isDGeneratedAudiosNil))
                .disabled(isDGeneratedAudiosNil)
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
                if let state = loadingState, state == .generate_music {
                    Text(state.description)
                }
                
                let isGenerateMusicButtonDisable = videoToMusicData.description.isEmpty
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
        }
        
        
    }
}
