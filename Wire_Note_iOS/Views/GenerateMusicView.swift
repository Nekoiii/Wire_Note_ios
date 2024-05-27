import SwiftUI

struct GenerateMusicView: View {
    @State private var generateMode: GenerateMode = .generate
    @State private var prompt: String = ""
    @State private var style: String = ""
    @State private var title: String = ""
    @State private var makeInstrumental: Bool = false
    @State private var generatedAudioUrls: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Picker("Generate Mode", selection: $generateMode) {
                Text("Generate").tag(GenerateMode.generate)
                Text("Custom Generate").tag(GenerateMode.customGenerate)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            
            TextField("Enter \(generateMode == .customGenerate ? "lyrics":"prompt")", text: $prompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            if generateMode == .customGenerate {
                TextField("Enter style", text: $style)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Enter title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }
            
            Button(action: generatemAudio) {
                Text("Generate")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            
            Toggle(isOn: $makeInstrumental) {
                Text("Make Instrumental")
            }
            .padding()
            
            if !generatedAudioUrls.isEmpty {
                Text("Generated Audios: ")
                    .padding()
                ForEach(generatedAudioUrls, id: \.self) { AudioUrl in
                    AudioPlayerView(url:URL(string:AudioUrl)! )
                }
            }
        }
        .padding()
    }
    
    func generatemAudio() {
        let generatePrompt = prompt.isEmpty ? "Happy" : prompt
        let generateTags = style.isEmpty ? "kpop,Chinese" : style
        let generateTitle = title.isEmpty ? "My Song" : title
        let generateMakeInstrumental = (prompt.isEmpty && generateMode == .customGenerate) ? true : makeInstrumental
        let waitAudio = true
        
        let sunoGenerateAPI = SunoGenerateAPI(generateMode: generateMode)
        sunoGenerateAPI.generatemAudio(generateMode:generateMode,prompt: generatePrompt, tags: generateTags, title: generateTitle, makeInstrumental: generateMakeInstrumental, waitAudio: waitAudio) { sunoGenerateResponses, error in
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

struct GenerateMusicView_Previews: PreviewProvider {
    static var previews: some View {
        GenerateMusicView()
    }
}
