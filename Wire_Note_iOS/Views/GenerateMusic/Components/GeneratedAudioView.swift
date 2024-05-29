import SwiftUI

struct GeneratedAudioView: View {
    @Binding var generatedAudioUrls: [URL]
    
    var body: some View {
        VStack(alignment: .leading){
            if !generatedAudioUrls.isEmpty {
                Text("Generated Audios: ")
                    .padding()
                ForEach(generatedAudioUrls, id: \.self) { AudioUrl in
                    AudioPlayerView(url: AudioUrl )
                }
            }
        }
    }
}


struct GeneratedAudioView_Previews: PreviewProvider {
    @State static var audioUrls: [URL] = {
        guard let audio1Data = NSDataAsset(name: "audio-1")?.data,
              let audio2Data = NSDataAsset(name: "audio-2")?.data else {
            return []
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let audio1URL = tempDir.appendingPathComponent("audio-1.mp3")
        let audio2URL = tempDir.appendingPathComponent("audio-2.mp3")
        
        do {
            try audio1Data.write(to: audio1URL)
            try audio2Data.write(to: audio2URL)
        } catch {
            print("Error writing audio files: \(error)")
            return []
        }
        
        return [audio1URL, audio2URL]
    }()
    
    static var previews: some View {
        GeneratedAudioView(generatedAudioUrls: $audioUrls)
    }
}

