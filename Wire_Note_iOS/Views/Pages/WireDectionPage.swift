import SwiftUI
import AVKit

struct WireDectionPage: View {
    @State private var originVideoURL: URL?
    @State private var processedVideoURL: URL?
    
    @State private var player: AVPlayer?
    
    @State private var isPickerPresented = false
    @State private var isProcessing = false
    @State private var isVideoPlaying = false
    @State private var isShowingOriginVideo = true
    
    var body: some View {
        VStack {
            videoDisplayArea
            videoControlArea
        }
        .onAppear {
            let url = Paths.projectRootPath.appendingPathComponent("Assets.xcassets/Videos/sky-1.dataset/sky-1.MOV")
            print("Test video url: \(url.path)")
            if FileManager.default.fileExists(atPath: url.path) {
                print("Video file exists")
                originVideoURL = url
                player = AVPlayer(url: url)
            } else {
                print("Video file does not exist at path: \(url.path)")
            }
            
            originVideoURL = url
            player = AVPlayer(url: url)
        }
        .sheet(isPresented: $isPickerPresented, onDismiss: setupPlayer) {
            VideoPicker(videoURL: $originVideoURL)
        }
    }
    
    private var videoDisplayArea:some View{
        Group{
            Text("originVideoURL: \(originVideoURL?.absoluteString ?? "")")
            Text("processedVideoURL: \(processedVideoURL?.absoluteString ?? "")")
            if let originVideoURL = originVideoURL {
                if isProcessing {
                    VStack {
                        Text("Processing ...")
                            .font(.title)
                            .foregroundColor(Color("AccentColor"))
                            .padding()
                            .zIndex(1)
                        Spacer()
                    }
                    .frame(height: 300)
                }
                
                if processedVideoURL != nil {
                    Button(action: {}) {
                        Text("Show Origin Video")
                    }
                    .onLongPressGesture(minimumDuration: 0.1, pressing: { isPressing in
                        isShowingOriginVideo = isPressing
                    }, perform: {})
                }
                
                ZStack {
                    // Only show origin video when there is no processed video.
                    VideoPlayer(player: AVPlayer(url: originVideoURL))
                        .frame(height: 300)
                        .opacity(isShowingOriginVideo ? 1 : 0)
                    
                    // Show processed video above the original video.
                    if let processedVideoURL = processedVideoURL {
                        VideoPlayer(player: AVPlayer(url: processedVideoURL))
                            .frame(height: 300)
                            .opacity(isShowingOriginVideo ? 0 : 1)
                    }
                }
            }
        }
    }
    
    private var videoControlArea:some View{
        VStack {
            if originVideoURL != nil{
                Button(action: {
                    togglePlayback()
                }) {
                    Image(systemName: isVideoPlaying ? "pause.circle" : "play.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                }
            }
              
            Button("Upload Video") {
                isPickerPresented = true
            }
            .buttonStyle(SolidButtonStyle(buttonColor: Color("AccentColor")))
            .padding()
            
            Button("Detect Wires") {
                if let videoURL = originVideoURL {
                    processVideo(url: videoURL)
                }
            }
            .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: originVideoURL == nil ))
            .padding()
        }
    }
    
    func togglePlayback() {
        guard let player = player else { return }
        
        isVideoPlaying ? player.pause() : player.play()
        isVideoPlaying.toggle()
    }
    
    func setupPlayer() {
        if let url = originVideoURL {
            player = AVPlayer(url: url)
        }
    }
    
    func processVideo(url: URL) {
        let videoController = VideoWireDetectController()
        let outputPath = Paths.downloadedFilesFolderPath.appendingPathComponent("processed_video.mp4")
        videoController.processVideoWithWireDDetection(inputURL: url, outputURL: outputPath) { success in
            if success {
                DispatchQueue.main.async {
                    self.processedVideoURL = outputPath
                }
            }
        }
    }
}

struct WireDectionPage_Previews: PreviewProvider {
    static var previews: some View {
        WireDectionPage()
    }
}
