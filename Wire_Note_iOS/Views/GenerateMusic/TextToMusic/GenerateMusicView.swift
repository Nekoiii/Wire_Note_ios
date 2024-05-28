import SwiftUI

struct TextToMusicView: View {
    @State private var generateMode: GenerateMode = .generate
    @State private var prompt: String = ""
    @State private var style: String = ""
    @State private var title: String = ""
    @State private var isMakeInstrumental: Bool = false
    @State private var generatedAudioUrls: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Group{
                generateModePicker
                generateFields
                generatemMusicButton
                instrumentalToggle
                generatedAudioSection
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private var generateModePicker: some View {
        Picker("Generate Mode", selection: $generateMode) {
            Text("Generate").tag(GenerateMode.generate)
            Text("Custom Generate").tag(GenerateMode.customGenerate)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.vertical, 10)
    }
    private var generateFields: some View {
        Group {
            TextField("Enter \(generateMode == .customGenerate ? "lyrics":"prompt")", text: $prompt)
            if generateMode == .customGenerate {
                TextField("Enter style", text: $style)
                TextField("Enter title", text: $title)
            }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding(.vertical, 5)
    }
    private var instrumentalToggle: some View {
        InstrumentalToggle(isMakeInstrumental:$isMakeInstrumental)
    }
    private var generatemMusicButton: some View {
        Button(action: generatemMusic) {
            Text("Generate")
        }
        .buttonStyle(SolidButtonStyle(buttonColor: Color("AccentColor"), isDisable: false))
    }
    
    private var generatedAudioSection: some View {
        VStack(alignment: .leading) {
            Text("Generated Audios: ")
                .padding()
            ForEach(generatedAudioUrls, id: \.self) { audioUrl in
                AudioPlayerView(url: URL(string: audioUrl)!)
            }
        }
    }
    
    func generatemMusic() {
        let generatePrompt = prompt.isEmpty ? "Good morning" : prompt
        let generateTags = style.isEmpty ? "kpop, Chinese" : style
        let generateTitle = title.isEmpty ? "My Song" : title
        let generateIsMakeInstrumental = (prompt.isEmpty && generateMode == .customGenerate) ? true : isMakeInstrumental
        let waitAudio = true
        
        let sunoGenerateAPI = SunoGenerateAPI(generateMode: generateMode)
        sunoGenerateAPI.generatemMusic(generateMode:generateMode,prompt: generatePrompt, tags: generateTags, title: generateTitle, makeInstrumental: generateIsMakeInstrumental, waitAudio: waitAudio) { sunoGenerateResponses, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error generating audio: \(error)")
                    self.generatedAudioUrls = ["Error generating audio"]
                } else if let responses = sunoGenerateResponses{
                    self.generatedAudioUrls = responses.compactMap { $0.audioUrl }
                    if self.generatedAudioUrls.isEmpty {
                        self.generatedAudioUrls = ["No audio URL found"]
                    }
                    for url in self.generatedAudioUrls {
                        print("Generated Audio: \(url)")
                    }
                } else {
                    self.generatedAudioUrls = ["No audio generated"]
                }
            }
        }
    }
}

struct TextToMusicView_Previews: PreviewProvider {
    static var previews: some View {
        TextToMusicView()
    }
}
