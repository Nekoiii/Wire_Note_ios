import SwiftUI

struct TextToMusicView: View {
    @State private var generateMode: GenerateMode = .generate
    @State private var prompt: String = ""
    @State private var style: String = ""
    @State private var title: String = ""
    @State private var isMakeInstrumental: Bool = false
    @State private var generatedAudioUrls: [URL] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Group{
                generateModePicker
                generateFields
                generatemMusicButton
                InstrumentalToggleView(isMakeInstrumental: $isMakeInstrumental)
                GeneratedAudioView(generatedAudioUrls: $generatedAudioUrls)
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
    
    private var generatemMusicButton: some View {
        Button(action: {
            Task {
                await generatemMusic()
            }
        }) {
            Text("Generate")
        }
        .buttonStyle(SolidButtonStyle(buttonColor: Color("AccentColor"), isDisable: false))
    }

    func generatemMusic() async {
        let generatePrompt = prompt.isEmpty ? "Good morning" : prompt
        let generateTags = style.isEmpty ? "kpop, Chinese" : style
        let generateTitle = title.isEmpty ? "My Song" : title
        let generateIsMakeInstrumental = (prompt.isEmpty && generateMode == .customGenerate) ? true : isMakeInstrumental
        
        let sunoGenerateAPI = SunoGenerateAPI(generateMode: generateMode)
        
        let audioUrls = await sunoGenerateAPI.generatemMusic(generateMode: generateMode, prompt: generatePrompt, tags: generateTags, title: generateTitle, makeInstrumental: generateIsMakeInstrumental)
        self.generatedAudioUrls = audioUrls
    }
    
    
}

struct TextToMusicView_Previews: PreviewProvider {
    static var previews: some View {
        TextToMusicView()
    }
}
