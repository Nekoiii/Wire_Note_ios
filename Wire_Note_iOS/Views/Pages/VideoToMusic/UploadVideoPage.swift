import AVKit
import SwiftUI

enum VideoToMusicPages {}

extension VideoToMusicPages {
    struct UploadVideoPage: View {
        static let pageTitle: String = "Video To Music"
        @EnvironmentObject private var videoToMusicData: VideoToMusicData
        @StateObject private var viewModel: UploadVideoViewModel

        init() {
            _viewModel = StateObject(wrappedValue: UploadVideoViewModel(videoToMusicData: nil))
        }

        var body: some View {
            VStack {
                videoArea
                navigateToVideoToMusicPageButton
            }
            .onAppear {
                guard viewModel.videoToMusicData == nil else { return }
                viewModel.setVideoToMusicData(videoToMusicData)

                if EnvironmentConfigs.debugMode { setDebugData() }
            }
            .environmentObject(videoToMusicData)
            .navigationTitle(Self.pageTitle)
        }

        private var videoArea: some View {
            Group {
                Button("Upload Video") {
                    viewModel.isPickerPresented = true
                }
                .buttonStyle(SolidButtonStyle(buttonColor: .accent))
                .padding()
                .sheet(isPresented: $viewModel.isPickerPresented, onDismiss: viewModel.setupVideoPlayer) {
                    VideoPicker(videoURL: $videoToMusicData.originVideoUrl)
                }

                VideoPlayer(player: viewModel.videoPlayer)
                    .frame(height: 200)
            }
        }

        private var navigateToVideoToMusicPageButton: some View {
            let isExtractFramesButtonDisable = videoToMusicData.originVideoUrl == nil
            return NavigationLink(destination: VideoToMusicPages.ExtractAndDescribeFramesPage().environmentObject(videoToMusicData)) {
                Text(VideoToMusicPages.ExtractAndDescribeFramesPage.pageTitle)
            }
            .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: isExtractFramesButtonDisable))
            .disabled(isExtractFramesButtonDisable)
        }

        private func setDebugData() {
            let url = Paths.projectRootPath.appendingPathComponent("Assets.xcassets/Videos/sky-1.dataset/sky-1.MOV")
            checkFileExistAndNonEmpty(at: url) { url in
                videoToMusicData.originVideoUrl = url
                viewModel.videoPlayer = AVPlayer(url: url)
            }
        }
    }
}

struct VideoToMusicPage_UploadVideoPage_Previews: PreviewProvider {
    @StateObject private static var videoToMusicData = VideoToMusicData()
    static var previews: some View {
        VideoToMusicPages.UploadVideoPage()
            .environmentObject(videoToMusicData)
    }
}
