import AVKit
import SwiftUI

enum VideoToMusicPages {}

extension VideoToMusicPages {
    struct UploadVideoPage: View {
        @StateObject private var videoToMusicData = VideoToMusicData()

        @State private var loadingState: LoadingState?
        @State private var videoPlayer: AVPlayer?

        @State private var isPickerPresented = false

        var body: some View {
            VStack {
                videoArea

                let isVideoUrlNil = videoToMusicData.videoUrl == nil
                NavigationLink(destination: VideoToMusicPages.ExtractAndDescribeFramesPage().environmentObject(videoToMusicData)) {
                    Text("-> Extract And Describe Frames")
                }
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isVideoUrlNil))
                .disabled(isVideoUrlNil)
            }
            .onAppear {
                // * for test
                //            let url = Paths.projectRootPath.appendingPathComponent("Assets.xcassets/Videos/sky-1.dataset/sky-1.MOV")
                //            videoUrl = url
                //            if FileManager.default.fileExists(atPath: url.path) {
                //                videoUrl = url
                //                videoPlayer = AVPlayer(url: url)
                //            }
            }
            .environmentObject(videoToMusicData)
        }

        private var videoArea: some View {
            Group {
                //            Text("videoUrl: \(videoUrl?.absoluteString ?? "")")
                Button("Upload Video") {
                    isPickerPresented = true
                }
                .buttonStyle(SolidButtonStyle(buttonColor: Color("AccentColor")))
                .padding()
                .sheet(isPresented: $isPickerPresented, onDismiss: setupVideoPlayer) {
                    VideoPicker(videoURL: $videoToMusicData.videoUrl)
                }

                VideoPlayer(player: videoPlayer)
                    .frame(height: 200)
            }
        }

        private func setupVideoPlayer() {
            if let url = videoToMusicData.videoUrl {
                videoPlayer = AVPlayer(url: url)
                print("setupVideoPlayer: \(String(describing: videoPlayer))")
            }
        }
    }
}

struct VideoToMusicPage_UploadVideoPage_Previews: PreviewProvider {
    static var previews: some View {
        VideoToMusicPages.UploadVideoPage()
    }
}
