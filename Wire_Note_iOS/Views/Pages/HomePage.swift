import SwiftUI

struct HomePage: View {
    @StateObject private var videoToMusicData = VideoToMusicData()

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    ForEach(musicalNotes, id: \.symbol) { note in
                        Text(note.symbol)
                            .font(.largeTitle)
                    }
                }.padding(.vertical, 30)
                VStack {
                    NavigationLink(destination: TextToMusicPage()) {
                        Text(TextToMusicPage.pageTitle)
                    }
                    NavigationLink(destination: ImageToMusicPage()) {
                        Text(ImageToMusicPage.pageTitle)
                    }
                    NavigationLink(destination: VideoToMusicPages.UploadVideoPage().environmentObject(videoToMusicData)) {
                        Text(VideoToMusicPages.UploadVideoPage.pageTitle)
                    }
                    Spacer().frame(height: 50)
                    NavigationLink(destination: CameraView(isDetectWire: true)) {
                        Text("Open Camera")
                    }
                    NavigationLink(destination: WireDetectionPage()) {
                        Text(WireDetectionPage.pageTitle)
                    }
                }
                .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: false))
                .padding(.vertical, 10)

                NavigationLink(destination: HistoryAudiosView(folderPath: Paths.downloadedFilesFolderPath)) {
                    HStack {
                        Image(systemName: "music.note.list")
                        Text(HistoryAudiosView.pageTitle)
                    }
                    .font(.system(size: 20))
                }
                .padding(EdgeInsets(top: 30, leading: 40, bottom: 0, trailing: 0))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    HomePage()
}
