import SwiftUI

extension VideoToMusicPages {
    struct ExtractAndDescribeFramesPage: View {
        @EnvironmentObject var videoToMusicData: VideoToMusicData
        @StateObject private var viewModel = ExtractAndDescribeFramesViewModel()

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
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isDescrptionNil))
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
                viewModel.doExtractRandomFrames()
            }
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
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor")))
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
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isExtractedFramesEmpty))
                .disabled(isExtractedFramesEmpty)

                if !videoToMusicData.description.isEmpty {
                    Text("Description: \(videoToMusicData.description)")
                }
            }
        }
    }
}
