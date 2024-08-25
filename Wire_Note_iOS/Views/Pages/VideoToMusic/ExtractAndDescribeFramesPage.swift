import SwiftUI

extension VideoToMusicPages {
    struct ExtractAndDescribeFramesPage: View {
        static let pageTitle: String = "Extract Frames"
        @EnvironmentObject var videoToMusicData: VideoToMusicData
        @StateObject private var viewModel: ExtractAndDescribeFramesViewModel

        init() {
            _viewModel = StateObject(wrappedValue: ExtractAndDescribeFramesViewModel(videoToMusicData: nil))
        }

        var body: some View {
            VStack {
                extractFramesArea
                describeFramesArea
                InstrumentalToggleView(isMakeInstrumental: $viewModel.isMakeInstrumental).padding()
                navigateToVideoToMusicPageButton
            }
            .sheet(isPresented: $viewModel.isImageViewerPresented) {
                imageViewerSheet
            }
            .onAppear {
                initializeViewModel()
                viewModel.doExtractRandomFrames()
            }
            .navigationTitle(Self.pageTitle)
        }

        private func initializeViewModel() {
            guard viewModel.videoToMusicData == nil else { return }
            viewModel.setVideoToMusicData(videoToMusicData)
        }

        private var extractFramesArea: some View {
            Group {
                if !viewModel.extractedFrames.isEmpty {
                    let columns = [GridItem(.adaptive(minimum: 100))]
                    GeometryReader { geometry in
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(viewModel.extractedFrames, id: \.self) { frame in
                                    Image(uiImage: frame)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .onTapGesture {
                                            viewModel.selectedImage = frame
                                            viewModel.isImageViewerPresented = true
                                        }
                                }
                            }
                            .frame(minHeight: geometry.size.height)
                        }
                    }
                    .frame(height: 300)
                } else {
                    Text("No frames extracted")
                        .padding(.top, 100)
                        .frame(height: 300)
                }
                Text(viewModel.loadingState == .extract_frames ? viewModel.loadingState?.description ?? " " : " ")
                    .padding(.bottom, 10)
                Button(action: { viewModel.doExtractRandomFrames() }) {
                    Text("Extract Frames Again")
                }
                .buttonStyle(BorderedButtonStyle(borderColor: .accent))
            }
        }

        private var describeFramesArea: some View {
            GeometryReader { _ in
                VStack {
                    let isExtractedFramesEmpty = viewModel.extractedFrames.isEmpty
                    HStack {
                        Spacer()
                        Button(action: { viewModel.describeFrames() }) {
                            Text("Frames To Text")
                        }
                        .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: isExtractedFramesEmpty))
                        .disabled(isExtractedFramesEmpty)
                        Spacer()
                    }

                    Text(viewModel.loadingState == .image_to_text ? viewModel.loadingState?.description ?? " " : videoToMusicData.description)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
        }

        private var navigateToVideoToMusicPageButton: some View {
            let isDescrptionNil = videoToMusicData.description.isEmpty
            return VStack {
                NavigationLink(destination: VideoToMusicPages.GenerateMusicPage(isMakeInstrumental: viewModel.isMakeInstrumental).environmentObject(videoToMusicData)) {
                    Text(VideoToMusicPages.GenerateMusicPage.pageTitle)
                }
                .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: isDescrptionNil))
                .disabled(isDescrptionNil)
            }
        }

        private var imageViewerSheet: some View {
            Group {
                if let selectedImage = viewModel.selectedImage {
                    ImageViewer(image: selectedImage)
                } else {
                    Text("No Image Selected.")
                }
            }
        }
    }
}

struct VideoToMusicPage_ExtractAndDescribeFramesPage_Previews: PreviewProvider {
    @StateObject private static var videoToMusicData = VideoToMusicData()
    static var previews: some View {
        VideoToMusicPages.ExtractAndDescribeFramesPage()
            .environmentObject(videoToMusicData)
    }
}
