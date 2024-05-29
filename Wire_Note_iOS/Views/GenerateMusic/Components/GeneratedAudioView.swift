import SwiftUI

struct GeneratedAudioView: View {
    @Binding var generatedAudioUrls: [String]
    
    var body: some View {
        VStack(alignment: .leading){
            if !generatedAudioUrls.isEmpty {
                Text("Generated Audios: ")
                    .padding()
                ForEach(generatedAudioUrls, id: \.self) { AudioUrl in
                    AudioPlayerView(url:URL(string:AudioUrl)! )
                }
            }
        }
    }
}
