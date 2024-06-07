import AVKit
import SwiftUI

struct VideoToMusicPage: View {
    @State private var loadingState: LoadingState?

    @State private var videoUrl: URL?
    @State private var videoPlayer: AVPlayer?

    @State private var extractedFrames: [UIImage] = []

    @State private var isPickerPresented = false

    @State private var selectedImage: UIImage? = nil
    @State private var isImageViewerPresented = false

    @State private var description: String = ""

    @State private var isMakeInstrumental: Bool = false
    @State private var generatedAudioUrls: [URL] = []

    var body: some View {
        VStack {
            videoArea
            extractFramesArea
            imageToTextArea
            generateMusicArea

            GeneratedAudioView(generatedAudioUrls: $generatedAudioUrls)
        }
        .sheet(isPresented: $isImageViewerPresented) { // *problem
            if let selectedImage = selectedImage {
                ImageViewer(image: selectedImage)
            } else {
                Text("No Image Selected")
            }
        }
        .onAppear {
            let url = Paths.projectRootPath.appendingPathComponent("Assets.xcassets/Videos/sky-1.dataset/sky-1.MOV")
            videoUrl = url
            if FileManager.default.fileExists(atPath: url.path) {
                videoUrl = url
                videoPlayer = AVPlayer(url: url)
            }
        }
    }

    private var videoArea: some View {
        Group {
            Text("videoUrl: \(videoUrl?.absoluteString ?? "")")
            Button("Upload Video") {
                isPickerPresented = true
            }
            .buttonStyle(SolidButtonStyle(buttonColor: Color("AccentColor")))
            .padding()
            .sheet(isPresented: $isPickerPresented, onDismiss: setupVideoPlayer) {
                VideoPicker(videoURL: $videoUrl)
            }

            VideoPlayer(player: videoPlayer)
                .frame(height: 200)
        }
    }

    private var extractFramesArea: some View {
        Group {
            if let state = loadingState, state == .extract_frames {
                Text(state.description)
            }

            let isVideoUrlNil = videoUrl == nil
            Button(action: { doExtractRandomFrames() }) {
                Text("Extract Frames")
            }
            .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isVideoUrlNil))
            .disabled(isVideoUrlNil)

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
        }
    }

    private var imageToTextArea: some View {
        Group {
            if let state = loadingState, state == .image_to_text {
                Text(state.description)
            }
            let isExtractedFramesEmpty = extractedFrames.isEmpty
            Button(action: { doImageToText() }) {
                Text("Describe Image")
            }
            .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isExtractedFramesEmpty))
            .disabled(isExtractedFramesEmpty)

            if !description.isEmpty {
                Text("Descriptions: \(description)")
            }
        }
    }

    // *unfinished: need to be refactor with same function in ImageToMusicPage.swift
    private var generateMusicArea: some View {
        Group {
            if let state = loadingState, state == .generate_music {
                Text(state.description)
            }

            let isGenerateMusicButtonDisable = description.isEmpty
            Button(action: {
                Task {
                    loadingState = .generate_music
                    await generateMusicWithDescription()
                    loadingState = nil
                }
            }) {
                Text("Generate music with image description")
            }
            .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: isGenerateMusicButtonDisable))
            .disabled(isGenerateMusicButtonDisable)

            InstrumentalToggleView(isMakeInstrumental: $isMakeInstrumental)
                .padding()
        }
    }

    private func generateMusicWithDescription() async {
        let generatePrompt = description
        let generateIsMakeInstrumental = isMakeInstrumental
        let generateMode = GenerateMode.generate

        let sunoGenerateAPI = SunoGenerateAPI(generateMode: generateMode)

        let audioUrls = await sunoGenerateAPI.generatemMusic(generateMode: generateMode, prompt: generatePrompt, makeInstrumental: generateIsMakeInstrumental)
        generatedAudioUrls = audioUrls
    }

    private func doImageToText() {
        loadingState = .image_to_text

        for image in extractedFrames {
            guard let imageData = image.pngData() else {
                print("doImageToText - no imageData")
                return
            }

            //            print("imageData: \(imageData)")
            imageToText(imageData: imageData) { result in
                switch result {
                case let .success(desc):
                    DispatchQueue.main.async {
                        if self.description.isEmpty {
                            self.description += desc
                        } else {
                            self.description += ". " + desc
                        }
                    }
                case let .failure(error):
                    DispatchQueue.main.async {
                        print("doImageToText - error: \(error.localizedDescription)")
                    }
                }
                loadingState = nil

                if self.description.count > 150 {
                    self.description = String(self.description.prefix(150))
                }
            }
        }
    }

    private func setupVideoPlayer() {
        if let url = videoUrl {
            videoPlayer = AVPlayer(url: url)
            print("setupVideoPlayer: \(String(describing: videoPlayer))")
        }
    }

    private func doExtractRandomFrames() {
        guard let videoUrl = videoUrl else {
            print("Video URL is nil")
            return
        }
        description = ""
        loadingState = .extract_frames
        extractRandomFrames(from: videoUrl, frameCount: 5) { extractedFrames in
            self.extractedFrames = extractedFrames
            loadingState = nil
        }
    }
}

struct VideoToMusicPage_Previews: PreviewProvider {
    static var previews: some View {
        VideoToMusicPage()
    }
}
