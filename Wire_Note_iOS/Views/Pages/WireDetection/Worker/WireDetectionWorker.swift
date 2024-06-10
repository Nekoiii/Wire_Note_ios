//
//  WireDetectionWorker.swift
//  Wire_Note_iOS
//
//  Created by John Smith on 2024/06/09.
//

import Foundation
import UIKit
import AVFoundation

typealias progressHandler = (Float, Error?) -> Void

// Error handling
enum WireDetectionError: Error {
    case invalidURL
    case processingFailed
    case cancelled
    case noVideoTrack
    case cannotAddReaderOutput
}

extension WireDetectionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .processingFailed:
            return "Processing failed"
        case .cancelled:
            return "Processing cancelled"
        case .noVideoTrack:
            return "No video track found"
        case .cannotAddReaderOutput:
            return "Cannot add reader output"
        }
    }
}

class WireDetectionWorker {
    
    struct VideoMetadata {
        let frameRate: Double
        let duration: CMTime
        let videoTrackNaturalSize: CGSize
        let totalFrames: Int
    }
    
    private let wireDetector = WireDetector()
    var handler: progressHandler?   // handler to report progress
    private var videoMetadata: VideoMetadata?
    private var unhandleFrames: [CVImageBuffer] = []  // unhandled frames
    private var detectingFrames: [CVImageBuffer] = []  // frames in detecting
    private var handledFrames: [UIImage] = []   // handled frames
    private var isJobCancelled = false
    private var isAllFramesQueued = false
    
    // thread for getting frames from video
    let bufferReadingQueue = DispatchQueue(label: "bufferReadingQueue")
    var lastReadFrameTime = CMTime.zero
    let MAX_BUFFER_FRAMES = 50
    // thread for processing frames
    let bufferProcessingQueue = DispatchQueue(label: "bufferProcessingQueue")
    
    var videoSize: CGSize {
        return videoMetadata?.videoTrackNaturalSize ?? .zero
    }
    var totalFrames: Int {
        return videoMetadata?.totalFrames ?? 0
    }
    
    
    func processVideo(url: URL, handler: @escaping progressHandler) async throws {
        unhandleFrames.removeAll()
        handledFrames.removeAll()
        detectingFrames.removeAll()
        self.handler = handler
        isJobCancelled = false
        guard FileManager.default.fileExists(atPath: url.path)
        else {
            throw WireDetectionError.invalidURL
        }
        let asset = AVAsset(url: url)
        let videoTrack = try await loadVideoMetadataAndTrack(asset: asset)
        bufferReadingQueue.async {
            do {
                try self.getFramesFromVideo(asset: asset, videoTrack: videoTrack, startTime: .zero)
            } catch {
                handler(0, error)
            }
        }
    }
    
    func cancelProcessing() {
        handler?(0, WireDetectionError.cancelled)
        isJobCancelled = true
        unhandleFrames.removeAll()
        handledFrames.removeAll()
        detectingFrames.removeAll()
    }
    
    // private methods
    // thread for getting frames from video
    
    private func loadVideoMetadataAndTrack(asset: AVAsset) async throws -> AVAssetTrack {
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw WireDetectionError.noVideoTrack
        }
        let framerate = try await videoTrack.load(.nominalFrameRate)
        let duration = try await asset.load(.duration)
        let videoTrackNaturalSize = try await videoTrack.load(.naturalSize)
        let metadata = VideoMetadata(frameRate: Double(framerate), duration: duration, videoTrackNaturalSize: videoTrackNaturalSize, totalFrames: Int(duration.seconds * Double(framerate)))
        self.videoMetadata = metadata
        return videoTrack
    }
    
    private func getFramesFromVideo(asset: AVAsset, videoTrack: AVAssetTrack, startTime: CMTime) throws {
        let videoReader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any]  = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
        if videoReader.canAdd(readerOutput) {
            videoReader.add(readerOutput)
        } else {
            throw WireDetectionError.cannotAddReaderOutput
        }
        guard let duration = videoMetadata?.duration else {
            throw WireDetectionError.processingFailed
        }
        videoReader.timeRange = CMTimeRange(start: startTime, duration: duration)
        videoReader.timeRange.duration = duration
        videoReader.startReading()
        var isAllFramesRead = true
        while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            if isJobCancelled {
                return
            }
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                continue
            }
            unhandleFrames.append(imageBuffer)
            if unhandleFrames.count >= MAX_BUFFER_FRAMES {
                isAllFramesRead = false
                lastReadFrameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                if detectingFrames.isEmpty {
                    detectingFrames.append(contentsOf: unhandleFrames)
                    queueFramesForDetection()
                } else {
                    detectingFrames.append(contentsOf: unhandleFrames)
                }
            }
        }
        if isAllFramesRead {
            isAllFramesQueued = true
            if unhandleFrames.count < MAX_BUFFER_FRAMES {
                detectingFrames.append(contentsOf: unhandleFrames)
                queueFramesForDetection()
            }
        }
    }
    
    private func queueFramesForDetection() {
        bufferProcessingQueue.async {
            print("queueFramesForDetection")
            while !self.detectingFrames.isEmpty {
                if self.isJobCancelled {
                    return
                }
                let imageBuffer = self.detectingFrames.removeFirst()
                guard let image = self.wireDetector.detection(pixelBuffer: imageBuffer, videoSize: self.videoSize) else {
                    continue
                }
                self.handledFrames.append(image)
                let progress = min(Float(self.handledFrames.count) / Float(self.totalFrames), 0.99)
                self.handler?(progress, nil)
            }
            if self.isAllFramesQueued {
                
            }
        }
    }
    
    var outputURL: URL {
        return URL(fileURLWithPath: "/Users/js/temp/output.mp4")
    }
    
    
    
    
}
