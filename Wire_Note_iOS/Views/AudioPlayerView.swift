import SwiftUI
import AVFoundation

struct AudioPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        VStack {
            Button(action: {
                if isPlaying {
                    player?.pause()
                } else {
                    if player == nil {
                        player = AVPlayer(url: url)
                    }
                    player?.play()
                }
                isPlaying.toggle()
            }) {
                Text("url: \(url)")
                Text(isPlaying ? "Pause" : "Play")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

struct AudioPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        if let dataAsset = NSDataAsset(name: "sampleAudio") {
            let tempDir = FileManager.default.temporaryDirectory
            let tempFileURL = tempDir.appendingPathComponent("sampleAudio.mp3")
            
            do {
                try dataAsset.data.write(to: tempFileURL)
                return AnyView(AudioPlayerView(url: tempFileURL))
            } catch {
                return AnyView(Text("Failed to write audio file: \(error.localizedDescription)"))
            }
        } else {
            return AnyView(Text("Sample audio file not found."))
        }
    }
}
