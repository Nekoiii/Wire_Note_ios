import SwiftUI


extension VideoToMusicPages {
    struct ExtractAndDescribeFramesPage: View {
        @EnvironmentObject var videoToMusicData: VideoToMusicData
        
        @State private var extractedFrames: [UIImage] = []
        @State private var selectedImage: UIImage? = nil
        @State private var isImageViewerPresented = false
        
        @State private var description: String = ""
        
        @State private var loadingState: LoadingState?
        
        var body: some View {
            VStack{
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
        
        private func doExtractRandomFrames(){
            guard let videoUrl = videoToMusicData.videoUrl else {
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
}







