//
//  VideoBufferReader.swift
//  Wire_Note_iOS
//
//  Created by John Smith on 2024/06/10.
//

import Foundation
import AVFoundation

protocol VideoBufferReaderDelegate: AnyObject {
    func videoBufferReaderDidFinishReading(buffers: [CVImageBuffer])
}

enum VideoBufferReaderError: Error {
    case noVideoTrack
    case cannotAddReaderOutput
    case invalidURL
}

class VideoBufferReader {
    
    // public properties
    var framerate: Float
    var duration: CMTime
    var videoSize: CGSize
    var totalFrames: Int
    var isAllFramesRead = false
    var isReadingBuffer = false
    
    // delegate
    weak var delegate: VideoBufferReaderDelegate?
    
    // video properties
    
    private var videoTrack: AVAssetTrack
    private var asset: AVAsset
    
    // video reader
    private var reader: AVAssetReader
    private let outputSettings: [String: Any]  = [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
    ]
    private let readerOutput: AVAssetReaderTrackOutput
    
    // thread
    private var isJobCancelled = false
    private var isReaderStarted = false
    private let bufferReadingQueue = DispatchQueue(label: "com.wirenote.bufferReadingQueue")
    
    init (url: URL) async throws {
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
        self.duration = try await asset.load(.duration)
        self.videoSize = try await videoTrack.load(.naturalSize)
        self.totalFrames = Int(duration.seconds * Double(framerate))
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
                buffers.append(imageBuffer)
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
        self.isReadingBuffer = false
        self.delegate?.videoBufferReaderDidFinishReading(buffers: buffers)
    }
    
    func cancelReading() {
        isJobCancelled = true
        reader.cancelReading()
    }
    
    
}
