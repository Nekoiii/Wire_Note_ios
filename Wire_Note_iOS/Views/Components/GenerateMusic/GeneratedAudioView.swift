import SwiftUI

struct GeneratedAudioView: View {
    @Binding var generatedAudioUrls: [URL]

    var body: some View {
        VStack(alignment: .leading) {
            if !generatedAudioUrls.isEmpty {
                TitleBar(title: "Generated Audios")

                ForEach(generatedAudioUrls, id: \.self) { AudioUrl in
                    AudioPlayerView(url: AudioUrl)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }
            }
        }
    }
}

struct GeneratedAudioView_Previews: PreviewProvider {
    @State static var audioUrls: [URL] = DemoFiles.audioUrls

    static var previews: some View {
        GeneratedAudioView(generatedAudioUrls: $audioUrls)
    }
}
