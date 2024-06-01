import CoreVideo

class VideoWireDetectController: VideoController {
    private let wireDetector = WireDetector()
    
    override func videoCapture(sampleBuffer: CVPixelBuffer, videoSize: CGSize) {
        guard let image = self.wireDetector.detection(pixelBuffer: sampleBuffer, videoSize: videoSize) else {
            print("Captured image is null")
            return
        }
        
        onFrameCaptured?(image)
    }
}
