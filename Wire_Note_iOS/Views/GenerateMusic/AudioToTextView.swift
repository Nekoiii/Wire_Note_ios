import SwiftUI

struct AudioToTextView: View {
    @State var audioUrl: URL?
    
    @State private var transcription: String = ""
    @State private var errorMessage: String?
    @State private var isLoadingTranscription: Bool = false
    
    var body: some View {
        VStack {
            doAudioToTextButton
            if !transcription.isEmpty {
                ScrollView(.vertical, showsIndicators: true){
                    Text(isLoadingTranscription ? "Loading ..." : "Lyrics detected from song: : \(transcription)")
                }
                .frame(maxHeight: 170)
            }
        }
    }
    
    private var doAudioToTextButton:some View{
        let isAudioUrlBlank = audioUrl == nil
        return Button(action: {doAudioToText()}) {
            Text("Transcribe Audio")
                .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"),isDisable: isAudioUrlBlank))
        .disabled(isAudioUrlBlank)
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
    @State static var audioUrl: URL? = {
        guard let audio1Data =  NSDataAsset(name: "audio-1")?.data
        else { return nil }
        let tempDir = FileManager.default.temporaryDirectory
        let audio1URL = tempDir.appendingPathComponent("audio-1.mp3")
        
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
