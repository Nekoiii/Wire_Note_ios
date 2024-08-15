import AVKit
import SwiftUI

enum VideoToMusicPages {}

extension VideoToMusicPages {
    struct UploadVideoPage: View {
        @EnvironmentObject private var videoToMusicData: VideoToMusicData
        @StateObject private var viewModel = UploadVideoViewModel()

        var body: some View {
            VStack {
                videoArea

                let isVideoUrlNil = videoToMusicData.originVideoUrl == nil
                NavigationLink(destination: VideoToMusicPages.ExtractAndDescribeFramesPage().environmentObject(videoToMusicData)) {
                    Text("-> Extract And Describe Frames")
                }
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isVideoUrlNil))
                .disabled(isVideoUrlNil)
            }
            .onAppear {
                if EnvironmentConfigs.debugMode {
                    let url = Paths.projectRootPath.appendingPathComponent("Assets.xcassets/Videos/sky-1.dataset/sky-1.MOV")
                    if FileManager.default.fileExists(atPath: url.path) {
                        videoToMusicData.originVideoUrl = url
                        viewModel.videoPlayer = AVPlayer(url: url)
                    }
                }
            }
            .environmentObject(videoToMusicData)
        }

        private var videoArea: some View {
            Group {
                Button("Upload Video") {
                    viewModel.isPickerPresented = true
                }
                .buttonStyle(SolidButtonStyle(buttonColor: Color("AccentColor")))
                .padding()
                .sheet(isPresented: $viewModel.isPickerPresented, onDismiss: viewModel.setupVideoPlayer) {
                    VideoPicker(videoURL: $videoToMusicData.originVideoUrl)
                }

                VideoPlayer(player: viewModel.videoPlayer)
                    .frame(height: 200)
            }
        }
    }
}

struct VideoToMusicPage_UploadVideoPage_Previews: PreviewProvider {
    static var previews: some View {
        VideoToMusicPages.UploadVideoPage()
    }
}
