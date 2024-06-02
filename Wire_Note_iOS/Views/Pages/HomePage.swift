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
                Group{
                    NavigationLink(destination: TextToMusicPage()) {
                        Text("Text To Music")
                    }
                    NavigationLink(destination: ImageToMusicPage()) {
                        Text("Image To Music")
                    }
                    NavigationLink(destination: CameraView(isDetectWire: false)) {
                        Text("Open Camera")
                    }
                    NavigationLink(destination: WireDectionPage()) {
                        Text("Wire Dection")
                    }
                    .padding(.top, 50)
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