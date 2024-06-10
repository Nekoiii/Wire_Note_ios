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
    case detectionFailed
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
        case .detectionFailed:
            return "Yolo detection failed"
        }
    }
}

class WireDetectionWorker {
    
    
    private let videoBufferReader: VideoBufferReader
    private let wireDetector = WireDetector()
    var handler: progressHandler?   // handler to report progress
    
    private var unhandleFrames: [CVImageBuffer] = []  // unhandled frames
    private var handledFrames: [CVImageBuffer] = []   // handled frames
    private var isJobCancelled = false
   
    // thread for processing frames
    var isProcessingFrames = false
    private let bufferProcessingQueue = DispatchQueue(label: "bufferProcessingQueue")
    private let PRELOAD_FRAMES = 10
    
    
    // video properties
    private var videoSize: CGSize {
        return videoBufferReader.videoSize
    }
    
    private var totalFrames: Int {
        return videoBufferReader.totalFrames
    }
    
    init (url: URL) async throws {
        self.videoBufferReader = try await VideoBufferReader(url: url)
        videoBufferReader.delegate = self
    }
    
    func processVideo(url: URL, handler: @escaping progressHandler) async throws {
        unhandleFrames.removeAll()
        handledFrames.removeAll()
        self.handler = handler
        isJobCancelled = false
        videoBufferReader.readBuffer()
    }
    
    func cancelProcessing() {
        handler?(0, WireDetectionError.cancelled)
        isJobCancelled = true
        unhandleFrames.removeAll()
        handledFrames.removeAll()
        videoBufferReader.cancelReading()
    }
    
    private func processUnhandledFrames() {
        if isProcessingFrames {
            return
        }
        isProcessingFrames = true
        bufferProcessingQueue.async {
            print("queueFramesForDetection")
            do {
                while !self.unhandleFrames.isEmpty {
                    if self.isJobCancelled {
                        return
                    }
                    let imageBuffer = self.unhandleFrames.removeFirst()
                    let startTs = Date().timeIntervalSince1970
                    let results = try self.wireDetector.detect(pixelBuffer: imageBuffer, videoSize: self.videoSize)
                    self.handledFrames.append(imageBuffer)
                    let progress = min(Float(self.handledFrames.count) / Float(self.totalFrames), 0.99)
                    print("Handled frames: \(self.handledFrames.count) / \(self.totalFrames)")
                    self.handler?(progress, nil)
                    print("Detection time: \(Date().timeIntervalSince1970 - startTs)")
                    if self.unhandleFrames.count < self.PRELOAD_FRAMES {
                        self.videoBufferReader.readBuffer()
                    }
                }
            } catch {
                self.handler?(0, error)
            }
            self.isProcessingFrames = false
        }
    }
    
    var outputURL: URL {
        return URL(fileURLWithPath: "/Users/js/temp/output.mp4")
    }
}

// MARK: - VideoBufferReaderDelegate
extension WireDetectionWorker: VideoBufferReaderDelegate {
    func videoBufferReaderDidFinishReading(buffers: [CVImageBuffer]) {
        unhandleFrames.append(contentsOf: buffers)
        processUnhandledFrames()
    }
}
