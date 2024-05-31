import SwiftUI

struct AudioToTextView: View {
    @State private var transcription: String = ""
    @State private var errorMessage: String?
    @State private var isLoadingTranscription: Bool = false
    
    var body: some View {
        VStack {
            Button(action: {doAudioToText()}) {
                Text("Transcribe Audio")
            }
            .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor")))
            Text("Lyrics detected from song: ")
            Text("\(isLoadingTranscription ? "Loading ..." :transcription)")
        }
    }
    private func doAudioToText(){
        isLoadingTranscription = true
        
        guard let audioAsset = NSDataAsset(name: "audio-2") else {
                    errorMessage = "Failed to load audio asset."
                    return
                }
        
        audioToText(audioData: audioAsset.data) { result in
            switch result {
            case .success(let transcription):
                DispatchQueue.main.async {
                    self.transcription = transcription
                    self.errorMessage = nil
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
            isLoadingTranscription = false
        }
        
    }
}

struct AudioToTextView_Previews: PreviewProvider {
    static var previews: some View {
        AudioToTextView()
    }
}
