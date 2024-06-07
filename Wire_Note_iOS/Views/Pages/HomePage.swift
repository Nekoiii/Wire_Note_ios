import SwiftUI

struct HomePage: View {
    var body:some View{
        NavigationView{
            VStack{
                HStack{
                    ForEach(musicalNotes, id: \.symbol) { note in
                        Text(note.symbol)
                            .font(.largeTitle)
                        
                    }
                }.padding(.vertical ,30)
                VStack{
                    NavigationLink(destination: TextToMusicPage()) {
                        Text("Text To Music")
                    }
                    NavigationLink(destination: ImageToMusicPage()) {
                        Text("Image To Music")
                    }
                    NavigationLink(destination: VideoToMusicPage()) {
                        Text("Video To Music")
                    }
                    Spacer().frame(height: 50)
                    NavigationLink(destination: CameraView(isDetectWire: true)) {
                        Text("Open Camera")
                    }
                    NavigationLink(destination: WireDetectionPage()) {
                        Text("Wire Detection")
                    }
                }
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: false))
                .padding(.vertical, 10)
                
                NavigationLink(destination: HistoryAudiosView(folderPath: Paths.downloadedFilesFolderPath)) {
                    Label("History", systemImage: "music.note.list")
                        .font(.system(size: 20))
                }
                .padding(.vertical, 30)
                .padding(.leading, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    
}
#Preview{
    HomePage()
}
