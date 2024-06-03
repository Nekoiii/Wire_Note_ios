import CoreVideo
import AVFoundation
import CoreML

class VideoWireDetectController: VideoController {
    private let wireDetector = WireDetector()
    
    // https://stackoverflow.com/questions/27608510/avfoundation-add-first-frame-to-video
    private var videoReader: AVAssetReader?
    private var videoWriter: AVAssetWriter?
    private var asset: AVAsset?
    
    override func videoCapture(sampleBuffer: CVPixelBuffer, videoSize: CGSize) {
//        print("VideoWireDetectController - videoCapture")
        guard let image = self.wireDetector.detection(pixelBuffer: sampleBuffer, videoSize: videoSize) else {
            print("Captured image is null")
            return
        }
        onFrameCaptured?(image)
    }
    
    
    func processVideoWithWireDetection(inputURL: URL, outputURL: URL, completion: @escaping (Bool) -> Void){
        Task{
            do{
//                let asset = AVAsset(url: inputURL)
                self.asset = AVAsset(url: inputURL)
                
                // Create videoWriter, videoReader, videoTracks
                guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
                    print("Failed to create AVAssetWriter")
                    completion(false)
                    return
                }
                self.videoWriter = videoWriter
                
                guard let videoReader = try? AVAssetReader(asset: self.asset!) else {
                    print("Failed to create AVAssetReader")
                    completion(false)
                    return
                }
                self.videoReader = videoReader
                
                let videoTracks = try await self.asset!.loadTracks(withMediaType: .video)
                guard let videoTrack = videoTracks.first else {
                    print("No video tracks found")
                    completion(false)
                    return
                }
                print("videoTracks: \(videoTracks)")

                // Settings for read and output
                let outputSettings: [String: Any]  = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
                if self.videoReader!.canAdd(readerOutput) {
                    self.videoReader!.add(readerOutput)
                } else {
                    print("Failed to add readerOutput to videoReader")
                    completion(false)
                    return
                }
                
                
                // Settings for write and input
                let videoTrackNaturalSize = try await videoTrack.load(.naturalSize)
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: videoTrackNaturalSize.width,
                    AVVideoHeightKey: videoTrackNaturalSize.height
                ]
                let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                if self.videoWriter!.canAdd(writerInput) {
                    self.videoWriter!.add(writerInput)
                } else {
                    print("Failed to add writerInput to videoWriter")
                    completion(false)
                    return
                }
                
                
                let sourcePixelBufferAttributes: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                    kCVPixelBufferWidthKey as String: videoTrackNaturalSize.width,
                    kCVPixelBufferHeightKey as String: videoTrackNaturalSize.height,
                    kCVPixelBufferIOSurfacePropertiesKey as String: [:]
                ]
                let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)

                
                
                // start
                self.videoReader!.startReading()
                self.videoWriter!.startWriting()
                self.videoWriter!.startSession(atSourceTime: .zero)
                

                //*for test
                let processingQueue = DispatchQueue(label: "processingQueue")
                writerInput.requestMediaDataWhenReady(on: processingQueue) {
                    while writerInput.isReadyForMoreMediaData {
                        if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                            writerInput.append(sampleBuffer)
                        } else {
                            writerInput.markAsFinished()
                            self.videoWriter!.finishWriting {
                                print("videoWriter -- finishWriting")
                                completion(true)
                            }
                            break
                        }
                    }
                }
                
                
//                let processingQueue = DispatchQueue(label: "videoProcessingQueue")
//                writerInput.requestMediaDataWhenReady(on: processingQueue) {
//                    while writerInput.isReadyForMoreMediaData {
//                        if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
//                            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
//                                let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//                                if let detectedImage = self.wireDetector.detection(pixelBuffer: pixelBuffer, videoSize: videoTrackNaturalSize),
//                                   let detectedBuffer = detectedImage.pixelBuffer() {
//                                    
//                                    let pixelFormat = CVPixelBufferGetPixelFormatType(detectedBuffer)
//                                    let width = CVPixelBufferGetWidth(detectedBuffer)
//                                    let height = CVPixelBufferGetHeight(detectedBuffer)
//                                    if pixelFormat == kCVPixelFormatType_32BGRA && width == Int(videoTrackNaturalSize.width) && height == Int(videoTrackNaturalSize.height) {
//                                        if !pixelBufferAdaptor.append(detectedBuffer, withPresentationTime: presentationTime) {
//                                            print("Failed to append pixel buffer")
//                                            videoReader.cancelReading()
//                                            completion(false)
//                                            return
//                                        }
//                                    } else {
//                                        print("Detected buffer format mismatch")
//                                    }
//                                } else {
//                                    print("Detection failed, skipping frame")
//                                }
//                            } else {
//                                print("Failed to get pixel buffer from sample buffer")
//                            }
//                        } else {
//                            writerInput.markAsFinished()
//                            videoWriter.finishWriting {
//                                if videoWriter.status == .completed {
//                                    print("Video processing completed successfully")
//                                    completion(true)
//                                } else {
//                                    print("Video writer status after reader failed: \(videoWriter.status.rawValue), error: \(String(describing: videoWriter.error))")
//                                    completion(false)
//                                }
//                            }
//                            break
//                        }
//                    }
//                }
            }catch {
                print("Error processing video: \(error.localizedDescription)")
                completion(false)
            }
            
        }
    }
}
