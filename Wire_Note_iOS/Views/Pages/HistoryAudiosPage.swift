import SwiftUI

struct HistoryAudiosView: View {
    @State private var audioUrls: [URL] = []
    var folderPath: URL

    var body: some View {
        VStack(alignment: .leading) {
            if audioUrls.isEmpty {
                Text("No downloaded audios")
            } else {
                List(audioUrls, id: \.self) { audioUrl in
                    AudioPlayerView(url: audioUrl)
                }
            }
        }
        .onAppear {
            loadDownloadedAudioUrls()
        }
        .navigationTitle("Music Generation History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadDownloadedAudioUrls() {
        do {
            let fileUrls = try FileManager.default.contentsOfDirectory(at: folderPath, includingPropertiesForKeys: nil)
            audioUrls = fileUrls.filter {
                FileTypes.isAudioFile(url: $0)
            }
        } catch {
            print("Error loading downloaded audio URLs: \(error)")
        }
    }
}

struct HistoryAudiosView_Previews: PreviewProvider {
    static var previews: some View {
        return NavigationView {
            HistoryAudiosView(folderPath: Paths.downloadedFilesFolderPath)
        }
    }
}
