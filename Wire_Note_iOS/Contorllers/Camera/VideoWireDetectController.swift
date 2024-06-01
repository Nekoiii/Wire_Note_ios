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
    
    
    func processVideoWithWireDDetection(inputURL: URL, outputURL: URL, completion: @escaping (Bool) -> Void){
        Task {
            do{
                let (reader, writer, videoTrack) = try await setupReaderWriter(inputURL: inputURL, outputURL: outputURL)
                
                guard let reader = reader, let writer = writer, let videoTrack = videoTrack else {
                    completion(false)
                    return
                }
                
                let (readerOutput, writerInput, adaptor) = await configureReaderAndWriter(reader: reader, writer: writer, videoTrack: videoTrack)
                
                guard let readerOutput = readerOutput, let writerInput = writerInput, let adaptor = adaptor else {
                    completion(false)
                    return
                }
                
                reader.startReading()
                writer.startWriting()
                writer.startSession(atSourceTime: .zero)
                
                await processFrameWithWireDetection(readerOutput: readerOutput, writerInput: writerInput, adaptor: adaptor, videoTrack: videoTrack, writer: writer, completion: completion)
            } catch {
                print("Error: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    func setupReaderWriter(inputURL: URL, outputURL: URL) async throws -> (AVAssetReader?, AVAssetWriter?, AVAssetTrack?) {
        let asset = AVAsset(url: inputURL)
        
        // Ensure that there is a video track in the asset.
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = tracks.first else {
            return (nil, nil, nil)
        }
        
        let reader = try AVAssetReader(asset: asset)
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        return (reader, writer, videoTrack)
    }
    
    func configureReaderAndWriter(reader: AVAssetReader, writer: AVAssetWriter, videoTrack: AVAssetTrack) async -> (AVAssetReaderTrackOutput?, AVAssetWriterInput?, AVAssetWriterInputPixelBufferAdaptor?) {
        do{
            // Read video frames from video tracks and add them to the AVAssetReader object.
            let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ])
            
            if reader.canAdd(readerOutput) {
                reader.add(readerOutput)
            } else {
                return (nil, nil, nil)
            }
            
            let naturalSize = try await videoTrack.load(.naturalSize)
            let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: naturalSize.width,
                AVVideoHeightKey: naturalSize.height
            ])
            
            // Add pixel buffer to AVAssetWriterInput.
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
            
            if writer.canAdd(writerInput) {
                writer.add(writerInput)
            } else {
                return (nil, nil, nil)
            }
            
            return (readerOutput, writerInput, adaptor)
            
        } catch {
            print("Error: \(error.localizedDescription)")
            return (nil, nil, nil)
        }
    }
    
    func processFrameWithWireDetection(readerOutput: AVAssetReaderTrackOutput, writerInput: AVAssetWriterInput, adaptor: AVAssetWriterInputPixelBufferAdaptor, videoTrack: AVAssetTrack, writer: AVAssetWriter, completion: @escaping (Bool) -> Void) async {
        let processingQueue = DispatchQueue(label: "frameProcessingQueue")
        let videoSize = try? await videoTrack.load(.naturalSize)
        
        writerInput.requestMediaDataWhenReady(on: processingQueue) {
            while writerInput.isReadyForMoreMediaData {
                if let sampleBuffer = readerOutput.copyNextSampleBuffer(), let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                    var newPixelBuffer: CVPixelBuffer?
                    let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    
                    if let detectedImage = self.wireDetector.detection(pixelBuffer: pixelBuffer, videoSize: videoSize ?? .zero) {
                        newPixelBuffer = detectedImage.pixelBuffer()
                    } else {
                        newPixelBuffer = pixelBuffer
                    }
                    
                    if let outputPixelBuffer = newPixelBuffer {
                        adaptor.append(outputPixelBuffer, withPresentationTime: timestamp)
                    }
                } else {
                    writerInput.markAsFinished()
                    writer.finishWriting {
                        switch writer.status {
                        case .completed:
                            completion(true)
                        default:
                            completion(false)
                        }
                    }
                    break
                }
            }
        }
    }
    
    
}
