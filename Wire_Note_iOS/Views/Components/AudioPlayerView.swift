import SwiftUI
import AVFoundation

struct AudioPlayerView: View {
    let url: URL
    @StateObject private var audioPlayerManager = AudioPlayerManager.shared
    
    var body: some View {
    
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    Text("\(url)")
                        .id("URL")
                        .onAppear {
                            // Scroll to the far right by default
                            DispatchQueue.main.async {
                                proxy.scrollTo("URL", anchor: .trailing)
                            }
                        }
                }
            }
            .padding(.leading,5)
            Button(action: {
                audioPlayerManager.play(url: url)
                
            }) {
                Text(audioPlayerManager.isCurrentPlayingUrl(url) && audioPlayerManager.isPlaying ? "Pause" : "Play")
                    .fixedSize(horizontal: true, vertical: false)
            }
            .buttonStyle(SolidButtonStyle(buttonColor: Color("AccentColor")))
        }
        .onDisappear {
            if audioPlayerManager.isCurrentPlayingUrl(url){
                audioPlayerManager.pause()
            }     
        }
    }
}

struct AudioPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        if let audio1 = NSDataAsset(name: "audio-1"),
           let audio2 = NSDataAsset(name: "audio-2"){
            let tempDir = FileManager.default.temporaryDirectory
            let tempFileURL1 = tempDir.appendingPathComponent("audio-1.mp3")
            let tempFileURL2 = tempDir.appendingPathComponent("audio-2.mp3")
            
            do {
                try audio1.data.write(to: tempFileURL1)
                try audio2.data.write(to: tempFileURL2)
                
                return AnyView(VStack {
                    AudioPlayerView(url: tempFileURL1)
                    AudioPlayerView(url: tempFileURL2)
                })
            } catch {
                return AnyView(Text("Failed to write audio file: \(error.localizedDescription)"))
            }
        } else {
            return AnyView(Text("Sample audio file not found."))
        }
    }
}
