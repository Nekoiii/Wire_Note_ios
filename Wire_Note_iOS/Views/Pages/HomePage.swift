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
                    NavigationLink(destination: TextToMusicView()) {
                        Text("Text To Music")
                    }
                    NavigationLink(destination: ImageToMusicView()) {
                        Text("Image To Music")
                    }
                    NavigationLink(destination: CameraView(isDetectWire: true)) {
                        Text("Open Camera")
                    }
                    .padding(.top, 50)
                }
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: false))
                .padding(.vertical, 10)
                
                NavigationLink(destination: HistoryAudiosView(folderPath: Paths.DownloadedFilesFolderPath)) {
                    Label("History", systemImage: "music.note.list")
                        .font(.system(size: 22))
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
