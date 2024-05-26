import SwiftUI

struct GenerateMusicView: View {
    @State private var lyrics: String = ""
    @State private var genre: String = ""
    @State private var generatedAudioUrls: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter lyrics", text: $lyrics)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Enter genre", text: $genre)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: generateCustomAudio) {
                Text("Generate")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            Text("Generated Audios: ")
                .padding()
            ForEach(generatedAudioUrls, id: \.self) { AudioUrl in
                AudioPlayerView(url:URL(string:AudioUrl)! )
            }
        }
        .padding()
    }
    
    func generateCustomAudio() {
        let prompt = lyrics
        let tags = genre
        let title = "Custom Song"
        let makeInstrumental = false
        let waitAudio = true
        
        let CustomGenerateAPI = CustomGenerateAPI()
        CustomGenerateAPI.generateCustomAudio(prompt: prompt, tags: tags, title: title, makeInstrumental: makeInstrumental, waitAudio: waitAudio) { customGenerateResponses, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error generating audio: \(error)")
                    self.generatedAudioUrls = ["Error generating audio"]
                } else if let responses = customGenerateResponses{
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
