import SwiftUI

struct CameraView: View {
    @StateObject var videoController = VideoController()
    @State private var img: UIImage?
    
    @State private var isDetectWire: Bool
    
    init(isDetectWire: Bool = false) {
        _isDetectWire = State(initialValue: isDetectWire)
        if isDetectWire {
            _videoController = StateObject(wrappedValue: VideoWireDetectController())
        } else {
            _videoController = StateObject(wrappedValue: VideoController())
        }
    }
    
    var body: some View {
        ZStack {
            if let image = img {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            VStack {
                Spacer()
                CameraControlsView()
            }
        }
        .maximize(alignment: .topLeading)
        .background(.black)
        .environmentObject(videoController)
        .onAppear {
            loadImage()
        }
    }
    
    func loadImage() {
        videoController.onFrameCaptured = { image in
            DispatchQueue.main.async {
                img = image
            }
        }
    }
}

#Preview {
    CameraView()
}
