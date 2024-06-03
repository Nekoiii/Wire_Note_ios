import CoreVideo
import AVFoundation

class VideoWireDetectController: VideoController {
    private let wireDetector = WireDetector()
    
    override func videoCapture(sampleBuffer: CVPixelBuffer, videoSize: CGSize) {
        guard let image = self.wireDetector.detection(pixelBuffer: sampleBuffer, videoSize: videoSize) else {
            print("Captured image is null")
            return
        }
        onFrameCaptured?(image)
    }
    
    
    func processVideoWithWireDetection(inputURL: URL, outputURL: URL, completion: @escaping (Bool) -> Void){
        Task{
            do{
                
                let asset = AVAsset(url: inputURL)
                guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
                    print("Failed to create AVAssetWriter")
                    completion(false)
                    return
                }
                
                guard let videoReader = try? AVAssetReader(asset: asset) else {
                    print("Failed to create AVAssetReader")
                    completion(false)
                    return
                }
                
                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                guard let videoTrack = videoTracks.first else {
                    print("No video tracks found")
                    completion(false)
                    return
                }
                
                let outputSettings: [String: Any]  = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
                videoReader.add(readerOutput)
                
                let videoTrackNaturalSize = try await videoTrack.load(.naturalSize)
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: videoTrackNaturalSize.width,
                    AVVideoHeightKey: videoTrackNaturalSize.height
                ]
                
                let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                
                let sourcePixelBufferAttributes: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                    kCVPixelBufferWidthKey as String: videoTrackNaturalSize.width,
                    kCVPixelBufferHeightKey as String: videoTrackNaturalSize.height,
                    kCVPixelBufferIOSurfacePropertiesKey as String: [:]
                ]
                let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
                videoWriter.add(writerInput)
                
                videoReader.startReading()
                videoWriter.startWriting()
                videoWriter.startSession(atSourceTime: .zero)
                
                let processingQueue = DispatchQueue(label: "videoProcessingQueue")
                writerInput.requestMediaDataWhenReady(on: processingQueue) {
                    while writerInput.isReadyForMoreMediaData {
                        if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                                let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                                if let detectedImage = self.wireDetector.detection(pixelBuffer: pixelBuffer, videoSize: videoTrackNaturalSize),
                                   let detectedBuffer = detectedImage.pixelBuffer() {
                                    
                                    let pixelFormat = CVPixelBufferGetPixelFormatType(detectedBuffer)
                                    let width = CVPixelBufferGetWidth(detectedBuffer)
                                    let height = CVPixelBufferGetHeight(detectedBuffer)
                                    //                            print("detectedImage: \(detectedImage)")
                                    //                            print("detectedBuffer: \(detectedBuffer)")
                                    //                            print("matched: \(pixelFormat == kCVPixelFormatType_32BGRA && width == Int(videoTrack.naturalSize.width) && height == Int(videoTrack.naturalSize.height) )")
                                    if pixelFormat == kCVPixelFormatType_32BGRA && width == Int(videoTrackNaturalSize.width) && height == Int(videoTrackNaturalSize.height) {
                                        if !pixelBufferAdaptor.append(detectedBuffer, withPresentationTime: presentationTime) {
                                            print("Failed to append pixel buffer")
                                            videoReader.cancelReading()
                                            completion(false)
                                            return
                                        }
                                        //                                print("pixelBufferAdaptor: \(pixelBufferAdaptor)")
                                    } else {
                                        print("Detected buffer format mismatch")
                                    }
                                } else {
                                    print("Detection failed, skipping frame")
                                }
                            } else {
                                print("Failed to get pixel buffer from sample buffer")
                            }
                        } else {
                            writerInput.markAsFinished()
                            videoWriter.finishWriting {
                                if videoWriter.status == .completed {
                                    print("Video processing completed successfully")
                                    completion(true)
                                } else {
                                    print("Video writer status after reader failed: \(videoWriter.status.rawValue), error: \(String(describing: videoWriter.error))")
                                    completion(false)
                                }
                            }
                            break
                        }
                    }
                }
                print("a")
            }
            
        }
    }
}
