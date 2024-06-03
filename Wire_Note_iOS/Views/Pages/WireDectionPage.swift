import SwiftUI
import AVKit

struct WireDectionPage: View {
    @State private var originVideoURL: URL?
    @State private var processedVideoURL: URL?
    
    @State private var originPlayer: AVPlayer?
    @State private var processedPlayer: AVPlayer?
    
    @State private var isPickerPresented = false
    @State private var isVideoPlaying = false
    @State private var isProcessing = false
    @State private var isShowingOriginVideo = true
    
    var body: some View {
        VStack {
            videoSettingsArea
            videoDisplayArea
            videoControlArea
        }
        .onAppear {
//            let url = Paths.projectRootPath.appendingPathComponent("Assets.xcassets/Videos/sky-1-mp4.dataset/sky-1-mp4.mp4")
            let url = Paths.projectRootPath.appendingPathComponent("Assets.xcassets/Videos/sky-1.dataset/sky-1.MOV")
//            print("Test video url: \(url.path)")
            
            if FileManager.default.fileExists(atPath: url.path) {
//                print("Video file exists")
                originVideoURL = url
                originPlayer = AVPlayer(url: url)
                if processedPlayer != nil {
                    originPlayer?.isMuted = true
                } else{
                    originPlayer?.isMuted = false
                }
                
            } else {
                print("Video file does not exist at path: \(url.path)")
            }
        }
        .sheet(isPresented: $isPickerPresented, onDismiss: setupOriginPlayers) {
            VideoPicker(videoURL: $originVideoURL)
        }
    }
    private var videoSettingsArea:some View{
        HStack{
            Spacer()
            if isProcessing {
                //                if !isProcessing {
                Text("Processing ...")
                    .font(.system(size: 20))
                    .foregroundColor(Color("AccentColor"))
                    .padding()
                    .zIndex(1)
            }
            if processedVideoURL != nil {
                //                if processedVideoURL == nil {
                Button(action: {}) {
                    Text("Show Origin Video")
                        .font(.system(size: 15))
                }
                .buttonStyle(SolidButtonStyle(buttonColor: Color("AccentColor")))
                .onLongPressGesture(minimumDuration: 0.1, pressing: { isPressing in
                    isShowingOriginVideo = isPressing
                    print("isPressing \(isPressing)")
                }, perform: {})
            }
        }
        .padding(.horizontal, 10)
    }
    
    private var videoDisplayArea:some View{
        Group{
            Text("originVideoURL: \(originVideoURL?.absoluteString ?? "")")
            Text("processedVideoURL: \(processedVideoURL?.absoluteString ?? "")")
            if let originPlayer = originPlayer {
                ZStack {
                    // Only show origin video when there is no processed video or pressing the ShowOriginVideo button.
                    VideoPlayer(player: originPlayer)
                        .frame(height: 300)
                        .opacity(isShowingOriginVideo ? 1 : 0)
                    
                    // Show processed video above the original video.
                    if let processedPlayer = processedPlayer {
                        VideoPlayer(player: processedPlayer)
                            .frame(height: 300)
                            .opacity(isShowingOriginVideo ? 0 : 1)
                    }
                }
            } else {
                Text("No video available")
            }
        }
    }
    
    private var videoControlArea:some View{
        VStack {
            if originPlayer != nil{
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
    
    private func togglePlayback() {
        if isVideoPlaying {
            originPlayer?.pause()
            processedPlayer?.pause()
        } else {
            // Synchronize the original video playback time with the processed video
            if let currentTime = originPlayer?.currentTime() {
                processedPlayer?.seek(to: currentTime)
            }
            originPlayer?.play()
            processedPlayer?.play()
        }
        
        isVideoPlaying.toggle()
    }
    
    private func setupOriginPlayers() {
        if let url = originVideoURL {
            processedPlayer = nil
            processedVideoURL = nil
            originPlayer = AVPlayer(url: url)
            print("setupOriginPlayers: \(String(describing: originPlayer))")
        }
    }
    
    private func setupProcessedPlayer(){
        if let url = processedVideoURL {
            processedPlayer = AVPlayer(url: url)
            processedPlayer?.isMuted = true
        }
    }
    
    private func processVideo(url: URL) {
        let videoWireDetectController = VideoWireDetectController()

        let outputPath = Paths.downloadedFilesFolderPath.appendingPathComponent("processed_video.mp4")
//        print("outputPath: \(outputPath)")
        
        removeExistingFile(at: outputPath)
        
        videoWireDetectController.processVideoWithWireDetection(inputURL: url, outputURL: outputPath) { success in
            if success {
                DispatchQueue.main.async {
                    checkFileExist(at: outputPath, onSuccess: { url in
                        self.processedVideoURL = url
                        self.setupProcessedPlayer()
                    }, onFailure: { path in
                        print("Processed video does not exist at path: \(path)")
                    })
                }
            } else {
                DispatchQueue.main.async {
                    print("Processed video failed")
                    self.isProcessing = false
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
