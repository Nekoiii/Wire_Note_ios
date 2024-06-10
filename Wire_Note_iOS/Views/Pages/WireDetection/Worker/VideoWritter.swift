//
//  VideoWritter.swift
//  Wire_Note_iOS
//
//  Created by John Smith on 2024/06/10.
//

import Foundation
import AVFoundation

enum VideoWritterError: Error {
    case writterNotInitialized
    case processingFailed
}

protocol VideoWritterDelegate: AnyObject {
    func videoWritterDidFinishWritingFrames()
    func videoWritterDidFinishWritingFile()
}

class VideoWritter {
    private var writter: AVAssetWriter?
    private var writterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var isWritterStarted = false
    
    // delegate
    weak var delegate: VideoWritterDelegate?
    
    // thread
    private let bufferWritingQueue = DispatchQueue(label: "com.wirenote.bufferWritingQueue")
    private var isWriting = false
    // frames
    private var frames: [CVPixelBuffer] = []
    private var frameCount = 0
    private var fps: CMTimeScale = 30
    
    func updateVideoSettings(outputURL: URL, videoSize: CGSize, fps: CMTimeScale) throws {
        // check output file exists
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        self.fps = fps
        let writter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height
        ]
        let writterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writterInput.expectsMediaDataInRealTime = true
        writter.add(writterInput)
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: videoSize.width,
            kCVPixelBufferHeightKey as String: videoSize.height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
        ]
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writterInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        self.writter = writter
        self.writterInput = writterInput
    }
    
    func start() throws {
        guard let writter = writter else {
            throw VideoWritterError.writterNotInitialized
        }
        writter.startWriting()
        writter.startSession(atSourceTime: .zero)
    }
    
    func finish() throws {
        guard let writter = writter,
              let writterInput = writterInput
        else {
            throw VideoWritterError.writterNotInitialized
        }
        writterInput.markAsFinished()
        writter.finishWriting {
            self.delegate?.videoWritterDidFinishWritingFile()
        }
    }
    
    func writeFrame(buffer: CVPixelBuffer) throws {
        frames.append(buffer)
        if !isWritterStarted {
            isWritterStarted = true
            try start()
        }
        if isWriting {
            return
        }
        isWriting = true
        bufferWritingQueue.async {
            while !self.frames.isEmpty {
                let frame = self.frames.removeFirst()
                guard let adapter = self.pixelBufferAdaptor else {
                    print("[Writter] pixel buffer adaptor not initialized")
                    continue
                }
                let presentationTime = CMTime(value: CMTimeValue(self.frameCount), timescale: self.fps)
                let success = adapter.append(frame, withPresentationTime: presentationTime)
                if !success {
                    print("[Writter] failed to append frame")
                    let error = self.writter?.error
                    print("[Writter] error: \(error?.localizedDescription ?? "unknown error")")
                } else {
                    print("[Writter] frame appended")
                }
                self.frameCount += 1
            }
            self.isWriting = false
            self.delegate?.videoWritterDidFinishWritingFrames()
        }
        
    }
}
