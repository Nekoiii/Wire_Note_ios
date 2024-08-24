import AVKit
import SwiftUI

enum VideoToMusicPages {}

extension VideoToMusicPages {
    struct UploadVideoPage: View {
        static let pageTitle: String = "Video To Music"
        @EnvironmentObject private var videoToMusicData: VideoToMusicData
        @StateObject private var viewModel: UploadVideoViewModel

        private var isExtractFramesButtonDisable: Bool { videoToMusicData.originVideoUrl == nil }

        init() {
            _viewModel = StateObject(wrappedValue: UploadVideoViewModel(videoToMusicData: nil))
        }

        var body: some View {
            VStack {
                videoArea
                extractFramesButton
            }
            .onAppear {
                guard viewModel.videoToMusicData == nil else { return }
                viewModel.setVideoToMusicData(videoToMusicData)

                if EnvironmentConfigs.debugMode { setDebugData() }
            }
            .environmentObject(videoToMusicData)
            .navigationTitle(VideoToMusicPages.UploadVideoPage.pageTitle)
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

        private var extractFramesButton: some View {
            NavigationLink(destination: VideoToMusicPages.ExtractAndDescribeFramesPage().environmentObject(videoToMusicData)) {
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
