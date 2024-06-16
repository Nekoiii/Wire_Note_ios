import SwiftUI

extension VideoToMusicPages {
    struct ExtractAndDescribeFramesPage: View {
        @EnvironmentObject var videoToMusicData: VideoToMusicData

        @State private var extractedFrames: [UIImage] = []
        @State private var selectedImage: UIImage? = nil
        @State private var isImageViewerPresented = false

        @State private var isMakeInstrumental: Bool = false

        @State private var loadingState: LoadingState?

        var body: some View {
            VStack {
                extractFramesArea
                describeFramesArea

                let isDescrptionNil = videoToMusicData.description.isEmpty
                VStack {
                    NavigationLink(destination: VideoToMusicPages.GenerateMusicPage(isMakeInstrumental: isMakeInstrumental).environmentObject(videoToMusicData)) {
                        Text("-> Generate Music")
                    }
                    InstrumentalToggleView(isMakeInstrumental: $isMakeInstrumental)
                }
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isDescrptionNil))
                .disabled(isDescrptionNil)
            }
            .sheet(isPresented: $isImageViewerPresented) { // *problem
                if let selectedImage = selectedImage {
                    ImageViewer(image: selectedImage)
                } else {
                    Text("No Image Selected")
                }
            }
            .onAppear {
                doExtractRandomFrames()
            }
        }

        private func doExtractRandomFrames() {
            guard let videoUrl = videoToMusicData.originVideoUrl else {
                print("Video URL is nil")
                return
            }
            videoToMusicData.description = ""
            loadingState = .extract_frames
            extractRandomFrames(from: videoUrl, frameCount: 6) { extractedFrames in
                self.extractedFrames = extractedFrames
                loadingState = nil
            }
        }

        private func describeFrames() {
            loadingState = .image_to_text

            for image in extractedFrames {
                guard let imageData = image.pngData() else {
                    print("describeFrames - no imageData")
                    return
                }

                imageToText(imageData: imageData) { result in
                    switch result {
                    case let .success(desc):
                        DispatchQueue.main.async {
                            if videoToMusicData.description.isEmpty {
                                videoToMusicData.description += desc
                            } else {
                                videoToMusicData.description += ". " + desc
                            }
                        }
                    case let .failure(error):
                        DispatchQueue.main.async {
                            print("describeFrames - error: \(error.localizedDescription)")
                        }
                    }
                    loadingState = nil

                    if videoToMusicData.description.count > 150 { // *unfinished
                        videoToMusicData.description = String(videoToMusicData.description.prefix(150))
                    }
                }
            }
        }

        private var extractFramesArea: some View {
            Group {
                if let state = loadingState, state == .extract_frames {
                    Text(state.description)
                }

                if !extractedFrames.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(extractedFrames, id: \.self) { frame in
                                Image(uiImage: frame)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .onTapGesture {
                                        selectedImage = frame
                                        print("onTapGesture -- Selected Image: \(selectedImage!)")
                                        isImageViewerPresented = true
                                    }
                            }
                        }
                    }
                } else {
                    Text("No frames extracted")
                }

                Button(action: { doExtractRandomFrames() }) {
                    Text("Extract Frames Again")
                }
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor")))
            }
        }

        private var describeFramesArea: some View {
            Group {
                if let state = loadingState, state == .image_to_text {
                    Text(state.description)
                }
                let isExtractedFramesEmpty = extractedFrames.isEmpty
                Button(action: { describeFrames() }) {
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
