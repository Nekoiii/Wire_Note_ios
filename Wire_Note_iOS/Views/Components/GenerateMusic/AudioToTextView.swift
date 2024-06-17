import SwiftUI

struct AudioToTextView: View {
    @State var audioUrl: URL?

    @State private var transcription: String = ""
    @State private var errorMessage: String?
    @State private var isLoadingTranscription: Bool = false

    @State private var isShowingTip = false

    var body: some View {
        VStack {
            doAudioToTextButton
            if !transcription.isEmpty {
                ScrollView(.vertical, showsIndicators: true) {
                    Text(isLoadingTranscription ? "Loading ..." : "Lyrics detected from song: : \(transcription)")
                }
                .frame(maxHeight: 170)
            }
        }
    }

    // This function will eat a lot of memory, so it has been disabled for now. 👻
    private var doAudioToTextButton: some View {
        //        let isAudioUrlBlank = audioUrl == nil
        let isAudioUrlBlank = true
        return VStack {
            Button(action: {
                isShowingTip.toggle()
                //            doAudioToText()
            }) {
                HStack {
                    Text("Transcribe Audio")
                        .fixedSize(horizontal: true, vertical: false)
                    Image(systemName: "info.circle")
                }
            }
            .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isAudioUrlBlank))
            //        .disabled(isAudioUrlBlank)
            .disabled(false)
            .overlay {
                if isShowingTip {
                    Text("This function will eat a lot of memory, so it has been disabled for now. 👻")
                        .font(.system(size: 15))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(10)
                        .background(Color.white)
                        .border(Color("AccentColor"))
                        .foregroundColor(Color("AccentColor"))
                        .frame(maxWidth: 200, alignment: .leading)
                        .zIndex(1)
                        .offset(y: -80)
                }
            }
        }
    }

    private func doAudioToText() {
        isLoadingTranscription = true

        guard let audioAsset = NSDataAsset(name: "song-2") else {
            errorMessage = "Failed to load audio asset."
            return
        }

        audioToText(audioData: audioAsset.data) { result in
            switch result {
            case let .success(transcription):
                DispatchQueue.main.async {
                    self.transcription = transcription
                    self.errorMessage = nil
                }
            case let .failure(error):
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
            isLoadingTranscription = false
        }
    }
}

struct AudioToTextView_Previews: PreviewProvider {
    @State static var audioUrl: URL? = {
        guard let audio1Data = NSDataAsset(name: "song-1")?.data
        else { return nil }
        let tempDir = FileManager.default.temporaryDirectory
        let audio1URL = tempDir.appendingPathComponent("song-1.mp3")

        do {
            try audio1Data.write(to: audio1URL)
        } catch {
            print("Error writing audio files: \(error)")
            return nil
        }

        return audio1URL
    }()

    static var previews: some View {
        AudioToTextView(audioUrl: audioUrl)
    }
}
