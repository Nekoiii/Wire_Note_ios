//
//  WireDetectionWorker.swift
//  Wire_Note_iOS
//
//  Created by John Smith on 2024/06/09.
//

import AVFoundation
import Foundation
import UIKit
import Vision

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
    private let renderer = VideoRenderer()
    private let writter = VideoWritter()

    var progressHandler: progressHandler? // handler to report progress

    private var unhandleFrames: [CVImageBuffer] = [] // unhandled frames

    private var isJobCancelled = false

    private var handledFramesCount = 0

    // thread for processing frames
    var isProcessingFrames = false
    private let bufferProcessingQueue = DispatchQueue(label: "bufferProcessingQueue")
    private let PRELOAD_FRAMES = 10
    private let outputURL: URL

    // video properties
    private var videoSize: CGSize {
        return videoBufferReader.videoSize
    }

    private var totalFrames: Int {
        return videoBufferReader.totalFrames
    }

    private var fps: CMTimeScale {
        return Int32(videoBufferReader.framerate)
    }

    init(inputURL: URL, outputURL: URL) async throws {
        self.outputURL = outputURL
        videoBufferReader = try await VideoBufferReader(url: inputURL)
        videoBufferReader.delegate = self
        renderer.updateVideoMetadata(videoSize: videoSize, detector: wireDetector)
        renderer.delegate = self
        try writter.updateVideoSettings(outputURL: outputURL, videoSize: videoSize, fps: fps)
        writter.delegate = self
    }

    func processVideo(url _: URL, handler: @escaping progressHandler) async throws {
        unhandleFrames.removeAll()
        progressHandler = handler
        isJobCancelled = false
        videoBufferReader.readBuffer()
    }

    func cancelProcessing() {
        progressHandler?(0, WireDetectionError.cancelled)
        isJobCancelled = true
        unhandleFrames.removeAll()
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
                    let result = try self.wireDetector.detect(pixelBuffer: imageBuffer, videoSize: self.videoSize)
                    self.handledFramesCount += 1
                    let progress = min(Float(self.handledFramesCount) / Float(self.totalFrames), 0.99)
                    print("Handled frames: \(self.handledFramesCount) / \(self.totalFrames)")
                    self.progressHandler?(progress, nil)
                    print("Detection time: \(Date().timeIntervalSince1970 - startTs)")
                    if self.unhandleFrames.count < self.PRELOAD_FRAMES {
                        self.videoBufferReader.readBuffer()
                    }
                    self.renderer.appendFrames(frame: imageBuffer, result: result)
                }
            } catch {
                self.progressHandler?(0, error)
            }
            self.isProcessingFrames = false
        }
    }
}

// MARK: - VideoBufferReaderDelegate

extension WireDetectionWorker: VideoBufferReaderDelegate {
    func videoBufferReaderDidFinishReading(buffers: [CVImageBuffer]) {
        print("videoBufferReaderDidFinishReading")
        unhandleFrames.append(contentsOf: buffers)
        processUnhandledFrames()
    }
}

extension WireDetectionWorker: VideoRendererDelegate {
    func videoRendererDidFinishRendering(buffer: CVPixelBuffer) {
        print("videoRendererDidFinishRendering")
        do {
            try writter.writeFrame(buffer: buffer)
        } catch {
            print("Failed to write frame: \(error)")
        }
    }
}

extension WireDetectionWorker: VideoWritterDelegate {
    var isAllProcessFinished: Bool {
        return videoBufferReader.isAllFramesRead && !isProcessingFrames && !renderer.isRendering
    }

    func videoWritterDidFinishWritingFrames() {
        print("videoWritterDidFinishWritingFrames")
        if isAllProcessFinished {
            do {
                try writter.finish()
            } catch {
                print("Failed to finish writter: \(error)")
            }
        } else {
            print("isAllFramesRead: \(videoBufferReader.isAllFramesRead), isProcessingFrames: \(isProcessingFrames), isRendering: \(renderer.isRendering)")
        }
    }

    func videoWritterDidFinishWritingFile() {
        print("videoWritterDidFinishWritingFile")
        progressHandler?(1, nil)
    }
}
