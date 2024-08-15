import AVFoundation
import Foundation
import UIKit

protocol VideoBufferReaderDelegate: AnyObject {
    func videoBufferReaderDidFinishReading(buffers: [CVImageBuffer])
}

enum VideoBufferReaderError: Error {
    case noVideoTrack
    case cannotAddReaderOutput
    case invalidURL
}

class VideoBufferReader {
    weak var delegate: VideoBufferReaderDelegate?

    // basic properties
    var framerate: Float
    var duration: CMTime
    var videoSize: CGSize
    var totalFrames: Int
    var orientation: CGAffineTransform
    var isAllFramesRead = false
    var isReadingBuffer = false

    // asset
    private var asset: AVAsset
    private var videoTrack: AVAssetTrack

    // video reader
    private var reader: AVAssetReader
    private let outputSettings: [String: Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
    ]
    private let readerOutput: AVAssetReaderTrackOutput

    // thread
    private let bufferReadingQueue = DispatchQueue(label: "com.wirenote.bufferReadingQueue")
    private var isJobCancelled = false
    private var isReaderStarted = false

    init(url: URL) async throws {
        guard FileManager.default.fileExists(atPath: url.path)
        else {
            throw VideoBufferReaderError.invalidURL
        }
        let asset = AVAsset(url: url)
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoBufferReaderError.noVideoTrack
        }
        let framerate = try await videoTrack.load(.nominalFrameRate)
        self.framerate = framerate
        duration = try await asset.load(.duration)
        videoSize = try await videoTrack.load(.naturalSize)
        totalFrames = Int(duration.seconds * Double(framerate))
        orientation = try await videoTrack.load(.preferredTransform)
        self.videoTrack = videoTrack
        self.asset = asset

        let reader = try AVAssetReader(asset: asset)
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        if reader.canAdd(readerOutput) {
            reader.add(readerOutput)
        } else {
            throw VideoBufferReaderError.cannotAddReaderOutput
        }
        self.reader = reader
        self.readerOutput = readerOutput
        reader.timeRange = CMTimeRange(start: .zero, duration: duration)
        reader.timeRange.duration = duration
    }

    func readBuffer() {
        if isReadingBuffer || isAllFramesRead {
            return
        }
        isReadingBuffer = true
        bufferReadingQueue.async {
            let MAX_BUFFER_FRAMES = 50
            var buffers: [CVImageBuffer] = []
            if !self.isReaderStarted {
                self.reader.startReading()
                self.isReaderStarted = true
            }
            while let sampleBuffer = self.readerOutput.copyNextSampleBuffer() {
                if self.isJobCancelled {
                    self.cancelReading()
                    return
                }
                guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                    continue
                }
                let image = UIImage(pixelBuffer: imageBuffer)
                let rotatedImage = image?.transformed(by: self.orientation)
                guard let rotatedPixelBuffer = rotatedImage?.pixelBuffer() else {
                    print("Can't create rotatedPixelBuffer")
                    continue
                }
                buffers.append(rotatedPixelBuffer)
                if buffers.count >= MAX_BUFFER_FRAMES {
                    self.readComplete(buffers: buffers)
                    return
                }
            }
            self.isAllFramesRead = true
            self.readComplete(buffers: buffers)
        }
    }

    private func readComplete(buffers: [CVImageBuffer]) {
        isReadingBuffer = false
        delegate?.videoBufferReaderDidFinishReading(buffers: buffers)
    }

    func cancelReading() {
        isJobCancelled = true
        reader.cancelReading()
    }
}