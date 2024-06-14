import AVFoundation
import UIKit
import Foundation

enum VideoWritterError: Error {
    case writterNotInitialized
    case processingFailed
}

protocol 
VideoWritterDelegate: AnyObject {
    func videoWritterDidFinishWritingFrames()
    func videoWritterDidFinishWritingFile()
}

class VideoWritter {
    private var writer: AVAssetWriter?
    private var writerInput: AVAssetWriterInput?
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
    private var orientation: CGAffineTransform = .identity

    func updateVideoSettings(outputURL: URL, videoSize: CGSize, fps: CMTimeScale, orientation: CGAffineTransform) throws {
        // check output file exists
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        self.fps = fps
        self.orientation = orientation
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height,
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.transform = orientation
        writerInput.expectsMediaDataInRealTime = true
        writer.add(writerInput)

        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: videoSize.width,
            kCVPixelBufferHeightKey as String: videoSize.height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
        ]
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)

        self.writer = writer
        self.writerInput = writerInput
    }

    func start() throws {
        guard let writer = writer else {
            throw VideoWritterError.writterNotInitialized
        }
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
    }

    func finish() throws {
        guard let writer = writer,
              let writerInput = writerInput
        else {
            throw VideoWritterError.writterNotInitialized
        }
        writerInput.markAsFinished()
        writer.finishWriting {
            self.delegate?.videoWritterDidFinishWritingFile()
        }
    }

    func writeFrame(buffer: CVPixelBuffer, orientation: CGAffineTransform) throws {
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
                
                let image = UIImage(pixelBuffer: frame)
                let rotatedImage = image?.transformed(by: orientation)
                guard let rotatedFrame = rotatedImage?.pixelBuffer() else {
                    print("Can't create rotatedPixelBuffer")
                    continue
                }
                
                guard let adapter = self.pixelBufferAdaptor else {
                    print("[writer] pixel buffer adaptor not initialized")
                    continue
                }
                let presentationTime = CMTime(value: CMTimeValue(self.frameCount), timescale: self.fps)
                let success = adapter.append(rotatedFrame, withPresentationTime: presentationTime)
                if !success {
                    print("[writer] failed to append frame")
                    let error = self.writer?.error
                    print("[writer] error: \(error?.localizedDescription ?? "unknown error")")
                } else {
                    print("[writer] frame appended")
                }
                self.frameCount += 1
            }
            self.isWriting = false
            self.delegate?.videoWritterDidFinishWritingFrames()
        }
    }
}
