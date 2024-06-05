import CoreVideo
import AVFoundation
import CoreML

class VideoWireDetectController: VideoController {
    private let wireDetector = WireDetector()
    
    // https://stackoverflow.com/questions/27608510/avfoundation-add-first-frame-to-video
    private var videoReader: AVAssetReader?
    private var videoWriter: AVAssetWriter?
    
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
                let asset = AVAsset(url: inputURL)
                
                // Create videoWriter, videoReader, videoTracks
                guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
                    print("Failed to create AVAssetWriter")
                    completion(false)
                    return
                }
                self.videoWriter = videoWriter
                
                guard let videoReader = try? AVAssetReader(asset: asset) else {
                    print("Failed to create AVAssetReader")
                    completion(false)
                    return
                }
                self.videoReader = videoReader
                
                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                guard let videoTrack = videoTracks.first else {
                    print("No video tracks found")
                    completion(false)
                    return
                }
                let orientation = videoTrack.preferredTransform.videoOrientation()
                print("Video orientation: \(orientation)")
                print("videoTracks: \(videoTracks)")
                
                // Settings for read and output
                let outputSettings: [String: Any]  = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
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
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                    kCVPixelBufferWidthKey as String: videoTrackNaturalSize.width,
                    kCVPixelBufferHeightKey as String: videoTrackNaturalSize.height,
                    kCVPixelBufferIOSurfacePropertiesKey as String: [:]
                ]
                let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
                
                // start
                self.videoReader!.startReading()
                self.videoWriter!.startWriting()
                self.videoWriter!.startSession(atSourceTime: .zero)
                
                
                let processingQueue = DispatchQueue(label: "processingQueue")
                writerInput.requestMediaDataWhenReady(on: processingQueue) {
                    while writerInput.isReadyForMoreMediaData {
                        if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                           
                            // Conversion between UIImage to CVPixelBuffer CVPixelBuffer to UIImage, CMSampleBuffer to UIImage: https://blog.csdn.net/watson2017/article/details/133786776
                            guard let  imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else{
                                print("Can't create imageBuffer")
                                return
                            }
                            
                            guard let srcImage = self.wireDetector.detection(pixelBuffer: imageBuffer , videoSize: videoTrackNaturalSize),
                                  let detectedImage = srcImage.rotated(by: orientation)
                            else {
                                print("Detect image is null")
                                return
                            }
//                            guard let detectedPixelBuffer = detectedImage.pixelBuffer() else {
//                                print("Can't create detectedPixelBuffer")
//                                return
//                            }
//                            //                            guard let detectedSampleBuffer = detectedPixelBuffer.toCMSampleBuffer() else {
//                            //                                print("Can't create detectedSampleBuffer")
//                            //                                return
//                            //                            }
//                            let pixelFormat = CVPixelBufferGetPixelFormatType(detectedPixelBuffer)
                            let frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//                            pixelBufferAdaptor.append(detectedPixelBuffer, withPresentationTime: frameTime)
                           let success = pixelBufferAdaptor.appendPixelBufferForImage(detectedImage, presentationTime: frameTime)
                            print("Append success: \(success)")
                            
                            //                            writerInput.append(detectedSampleBuffer)
                        } else {
                            writerInput.markAsFinished()
                            self.videoWriter!.finishWriting {
                                if self.videoWriter!.status == .completed {
                                    print("videoWriter -- finishWriting")
                                    print("Finished writing video")
                                    // Check if the processed video file valid
                                    let fileManager = FileManager.default
                                    
                                    do {
                                        let fileSize = try fileManager.attributesOfItem(atPath: outputURL.path)[.size] as? Int64
                                        if let size = fileSize, size > 0 {
                                            print("Processed video URL: \(outputURL)")
                                        } else {
                                            print("Processed video file is empty or invalid")
                                        }
                                    } catch {
                                        print("Error checking processed video file: \(error.localizedDescription)")
                                    }
                                    completion(true)
                                } else {
                                    //                                    print("Video writer failed: \(self.videoWriter!.error?.localizedDescription ?? "Unknown error")")
                                }
                            }
                        }
                    }
                }
            }catch {
                print("Error processing video: \(error.localizedDescription)")
                completion(false)
            }
            
        }
    }
}
