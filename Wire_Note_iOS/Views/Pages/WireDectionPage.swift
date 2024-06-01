//import SwiftUI
//import AVKit
//
//struct WireDectionPage: View {
//    @State private var originVideoURL: URL?
//    @State private var processedVideoURL: URL?
//    
//    @State private var player: AVPlayer?
//    
//    @State private var isPickerPresented = false
//    @State private var isProcessing = true
//    @State private var isVideoPlaying = false
//    @State private var isShowingOriginVideo = false
//    
//    var body: some View {
//        VStack {
//            videoDisplayArea
//            videoControlArea
//        }
//        .sheet(isPresented: $isPickerPresented) {
//            VideoPicker(videoURL: $originVideoURL)
//        }
//    }
//    
//    private var videoDisplayArea:some View{
//        if let originVideoURL = originVideoURL {
//            return Group{
//                if isProcessing {
//                    VStack {
//                        Text("Processing ...")
//                            .font(.title)
//                            .foregroundColor(Color("AccentColor"))
//                            .padding()
//                            .zIndex(1)
//                        Spacer()
//                    }
//                    .frame(height: 300)
//                }
//                
//                Button(action: {}) {
//                    Text("Show Origin Video")
//                }
//                .onLongPressGesture(minimumDuration: 0.1, pressing: { isPressing in
//                    isShowingOriginVideo = isPressing
//                }, perform: {})
//                
//                ZStack {
//                    // Only show origin video when there is no processed video.
//                    VideoPlayer(player: AVPlayer(url: originVideoURL))
//                        .frame(height: 300)
//                        .opacity(isShowingOriginVideo ? 1 : 0)
//                    
//                    // Show processed video above the original video.
//                    if let processedVideoURL = processedVideoURL {
//                        VideoPlayer(player: AVPlayer(url: processedVideoURL))
//                            .frame(height: 300)
//                            .opacity(isShowingOriginVideo ? 0 : 1)
//                    }
//                }
//            }
//        }
//    }
//    
//    private var videoControlArea:some View{
//        VStack {
//            Button(action: {
//                togglePlayback()
//            }) {
//                Image(systemName: isVideoPlaying ? "pause.circle" : "play.circle")
//                    .resizable()
//                    .frame(width: 50, height: 50)
//            }
//            .buttonStyle(SolidButtonStyle(buttonColor: Color("AccentColor")))
//            
//            
//            Button("Upload Video") {
//                isPickerPresented = true
//            }
//            .buttonStyle(SolidButtonStyle(buttonColor: Color("AccentColor")))
//            .padding()
//            
//            Button("Detect Wires") {
//                if let videoURL = originVideoURL {
//                    processVideo(url: videoURL)
//                }
//            }
//            .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"), isDisable: originVideoURL == nil ))
//            .padding()
//        }
//    }
//    
//    func togglePlayback() {
//        guard let player = player else { return }
//        
//        isVideoPlaying ? player.pause() : player.play()
//        isVideoPlaying.toggle()
//    }
//    
//    func processVideo(url: URL) {
//        let videoController = VideoController()
//        let outputPath = Paths.DownloadedFilesFolderPath.appendingPathComponent("processed_video.mp4")
//        videoController.processVideo(inputURL: url, outputURL: outputPath) { success in
//            if success {
//                DispatchQueue.main.async {
//                    self.processedVideoURL = outputPath
//                }
//            }
//        }
//    }
//}
//
//struct WireDectionPage_Previews: PreviewProvider {
//    static var previews: some View {
//        WireDectionPage()
//    }
//}
