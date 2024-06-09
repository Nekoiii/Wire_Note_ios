import AVFoundation
import CoreML
import CoreVideo
import UIKit

class VideoWireDetectController: VideoController {
    private let wireDetector = WireDetector()

    // https://stackoverflow.com/questions/27608510/avfoundation-add-first-frame-to-video
    private var videoReader: AVAssetReader?
    private var videoWriter: AVAssetWriter?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    private let batchSize = 5
    private var sampleBufferBatch: [CMSampleBuffer] = []
    private let processingQueue = DispatchQueue(label: "processingQueue")
    private let group = DispatchGroup()

    override func videoCapture(sampleBuffer: CVPixelBuffer, videoSize: CGSize) {
        guard let image = wireDetector.detection(pixelBuffer: sampleBuffer, videoSize: videoSize) else {
            print("Captured image is null")
            return
        }
        onFrameCaptured?(image)
    }

    func processVideoWithWireDetection(inputURL: URL, outputURL: URL, completion: @escaping (Bool) -> Void) {
        Task {
            do {
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

                // Just want to see how many frames in total
                let durationInSeconds = try await CMTimeGetSeconds(asset.load(.duration))
                let frameRate = try await videoTrack.load(.nominalFrameRate)
                let totalFrames = Int(durationInSeconds * Float64(frameRate))
                print("totalFrames: \(totalFrames)")

                // Settings for read and output
                let outputSettings: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
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
                    AVVideoHeightKey: videoTrackNaturalSize.height,
                ]
                let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)

                // Get orientation
                let orientation = try await videoTrack.load(.preferredTransform)
                writerInput.transform = orientation

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
                    kCVPixelBufferIOSurfacePropertiesKey as String: [:],
                ]
                pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)

                // start
                self.videoReader!.startReading()
                self.videoWriter!.startWriting()
                self.videoWriter!.startSession(atSourceTime: .zero)

                writerInput.requestMediaDataWhenReady(on: processingQueue) {
                    while writerInput.isReadyForMoreMediaData {
                        if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                            // Conversion between UIImage to CVPixelBuffer CVPixelBuffer to UIImage, CMSampleBuffer to UIImage: https://blog.csdn.net/watson2017/article/details/133786776
                            guard let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                                print("Can't create imageBuffer")
                                return
                            }

                            let image = UIImage(pixelBuffer: imageBuffer)
                            let rotatedImage = image?.transformed(by: orientation)
                            guard let rotatedPixelBuffer = rotatedImage?.pixelBuffer() else {
                                return
                            }

                            guard let detectedImage = self.wireDetector.detection(pixelBuffer: rotatedPixelBuffer, videoSize: videoTrackNaturalSize)
                            else {
                                print("Detect image is null")
                                return
                            }

                            let inverseTransform = orientation.inverted()
                            guard let finalImage = detectedImage.transformed(by: inverseTransform) else {
                                print("finalImage is null")
                                return
                            }

                            let frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                            let _ = self.pixelBufferAdaptor?.appendPixelBufferForImage(finalImage, presentationTime: frameTime)
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
                
//                writerInput.requestMediaDataWhenReady(on: self.processingQueue) {
//                    while writerInput.isReadyForMoreMediaData {
//                        if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
//                            self.sampleBufferBatch.append(sampleBuffer)
//
//                            let count = self.sampleBufferBatch.count
//                            if count == self.batchSize {
//                                print("group.enter()")
//                                self.group.enter()
//                                let sampleBufferBatch = self.sampleBufferBatch
//                                self.sampleBufferBatch.removeAll()
//                                self.processBatch(with: sampleBufferBatch, videoSize: videoTrackNaturalSize, orientation: orientation) { finalImages in
//                                    let frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//                                    for f in finalImages {
//                                        let _ = self.pixelBufferAdaptor!.appendPixelBufferForImage(f, presentationTime: frameTime)
//                                    }
//                                    print("group.leave()")
//                                    self.group.leave()
//                                }
//                            }
//                        } else {
//                            if !self.sampleBufferBatch.isEmpty {
//                                print("Processing remaining frames")
//                                self.group.enter()
//                                let sampleBufferBatch = self.sampleBufferBatch
//                                self.sampleBufferBatch.removeAll()
//                                self.processBatch(with: sampleBufferBatch, videoSize: videoTrackNaturalSize, orientation: orientation) { finalImages in
//                                    if let sampleBuffer = sampleBufferBatch.last {
//                                        let frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//                                        for f in finalImages {
//                                            let _ = self.pixelBufferAdaptor?.appendPixelBufferForImage(f, presentationTime: frameTime)
//                                        }
//                                    }
//                                    self.group.leave()
//                                }
//                            }
//
//                            writerInput.markAsFinished()
//                            print("writerInput.markAsFinished")
//                            
//                            
//                            //                            group.notify(queue: self.processingQueue) {
//                            self.group.notify(queue: .main) {
//                                let currentStatus = self.videoWriter?.status
//
//                                if currentStatus == .failed {
//                                    if let error = self.videoWriter?.error {
//                                        print("Final video writer error: \(error.localizedDescription)")
//                                    }
//                                    completion(false)
//                                } else if currentStatus == .writing {
////                                    writerInput.markAsFinished()
////                                    print("writerInput.markAsFinished")
//                                    self.videoWriter?.finishWriting {
//                                        let updatedStatus = self.videoWriter?.status
//                                        if updatedStatus == .completed {
//                                            print("videoWriter -- finishWriting")
//                                            checkFileExist(at: outputURL)
//                                            completion(true)
//                                        } else {
////                                            print("Video writer failed: \(String(describing: self.videoWriter?.error))")
//                                            print("Video writer failed: \(self.videoWriter?.error?.localizedDescription ?? "Unknown error")")
//                                            completion(false)
//                                        }
//                                    }
//                                } else {
//                                    print("Video writer is not in writing state: \(String(describing: self.videoWriter?.status.rawValue))")
//                                    completion(false)
//                                }
//                            }
//                            break
//                        }
//                    }
//                }
            } catch {
                print("Error processing video: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    private func processBatch(with sampleBuffers: [CMSampleBuffer], videoSize: CGSize, orientation: CGAffineTransform, completion: @escaping ([UIImage]) -> Void) {
        DispatchQueue.global().async {
            var finalImages: [UIImage] = []
            
            var rotatedPixelBuffers: [CVPixelBuffer] = []
            for s in sampleBuffers {
                guard let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(s) else {
                    print("Can't create imageBuffer")
                    continue
                }

                let image = UIImage(pixelBuffer: imageBuffer)
                let rotatedImage = image?.transformed(by: orientation)
                guard let rotatedPixelBuffer = rotatedImage?.pixelBuffer() else {
                    print("Can't create rotatedPixelBuffer")
                    continue
                }
                rotatedPixelBuffers.append(rotatedPixelBuffer)
            }

            let detectedImages = self.wireDetector.batchDetection(pixelBuffers: rotatedPixelBuffers, videoSize: videoSize)

            let inverseTransform = orientation.inverted()
            for i in detectedImages {
                guard let finalImage = i?.transformed(by: inverseTransform) else {
                    print("Can't create finalImage")
                    continue
                }
                finalImages.append(finalImage)
            }
            
            completion(finalImages)
        }
    }
}
