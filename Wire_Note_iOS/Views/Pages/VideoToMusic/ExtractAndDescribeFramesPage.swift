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

                let isDescrptionNil = videoToMusicData.description.isEmpty
                VStack {
                    NavigationLink(destination: VideoToMusicPages.GenerateMusicPage(isMakeInstrumental: viewModel.isMakeInstrumental).environmentObject(videoToMusicData)) {
                        Text("-> Generate Music")
                    }
                    InstrumentalToggleView(isMakeInstrumental: $viewModel.isMakeInstrumental)
                }
                .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: isDescrptionNil))
                .disabled(isDescrptionNil)
            }
            .sheet(isPresented: $viewModel.isImageViewerPresented) { // *problem
                if let selectedImage = viewModel.selectedImage {
                    ImageViewer(image: selectedImage)
                } else {
                    Text("No Image Selected")
                }
            }
            .onAppear {
                if viewModel.videoToMusicData == nil {
                    viewModel.setVideoToMusicData(videoToMusicData)
                }
                viewModel.doExtractRandomFrames()
            }
            .navigationTitle(VideoToMusicPages.ExtractAndDescribeFramesPage.pageTitle)
        }

        private var extractFramesArea: some View {
            Group {
                if let state = viewModel.loadingState, state == .extract_frames {
                    Text(state.description)
                }

                if !viewModel.extractedFrames.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(viewModel.extractedFrames, id: \.self) { frame in
                                Image(uiImage: frame)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .onTapGesture {
                                        viewModel.selectedImage = frame
                                        print("onTapGesture -- Selected Image: \(viewModel.selectedImage!)")
                                        viewModel.isImageViewerPresented = true
                                    }
                            }
                        }
                    }
                } else {
                    Text("No frames extracted")
                }

                Button(action: { viewModel.doExtractRandomFrames() }) {
                    Text("Extract Frames Again")
                }
                .buttonStyle(BorderedButtonStyle(borderColor: .accent))
            }
        }

        private var describeFramesArea: some View {
            Group {
                if let state = viewModel.loadingState, state == .image_to_text {
                    Text(state.description)
                }
                let isExtractedFramesEmpty = viewModel.extractedFrames.isEmpty
                Button(action: { viewModel.describeFrames() }) {
                    Text("Describe Image")
                }
                .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: isExtractedFramesEmpty))
                .disabled(isExtractedFramesEmpty)

                if !videoToMusicData.description.isEmpty {
                    Text("Description: \(videoToMusicData.description)")
                }
            }
        }
    }
}
