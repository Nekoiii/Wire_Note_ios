import Foundation
import UIKit
import Vision

protocol VideoRendererDelegate: AnyObject {
    func videoRendererDidFinishRendering(buffer: CVPixelBuffer)
}

class VideoRenderer {
    var delegate: VideoRendererDelegate?

    // frames and detect results rendering queue
    private var frames: [CVImageBuffer] = []
    private var results: [[VNRecognizedObjectObservation]] = []

    // thread for rendering frames
    private let bufferRenderingQueue = DispatchQueue(label: "com.wirenote.bufferRenderingQueue")
    var isRendering = false

    // video metadata
    private var videoSize: CGSize = .zero
    private var wireDetector: WireDetector?

    private var classes: [String] {
        return wireDetector?.classes ?? []
    }

    private var colors: [UIColor] {
        return wireDetector?.colors ?? []
    }

    // update video metadata
    func updateVideoMetadata(videoSize: CGSize, detector: WireDetector) {
        self.videoSize = videoSize
        wireDetector = detector
    }

    // rendering frames
    func appendFrames(frame: CVImageBuffer, result: [VNRecognizedObjectObservation]) {
        frames.append(frame)
        results.append(result)
        if isRendering {
            return
        }
        isRendering = true
        bufferRenderingQueue.async {
            var lastRenderedBuffer: CVPixelBuffer?
            while !self.frames.isEmpty {
                if let buffer = lastRenderedBuffer {
                    self.delegate?.videoRendererDidFinishRendering(buffer: buffer)
                }
                let frame = self.frames.removeFirst()
                let observations = self.results.removeFirst()
                var detections: [Detection] = []
                for result in observations {
                    let flippedBox = CGRect(x: result.boundingBox.minX, y: 1 - result.boundingBox.maxY, width: result.boundingBox.width, height: result.boundingBox.height)
                    let box = VNImageRectForNormalizedRect(flippedBox, Int(self.videoSize.width), Int(self.videoSize.height))
                    guard let label = result.labels.first?.identifier as? String,
                          let colorIndex = self.classes.firstIndex(of: label)
                    else {
                        print("WireDetector - Missing label or color index")
//                        results.append(pixelBufferToUIImage(pixelBuffer: pixelBuffer))
                        continue
                    }
                    let detection = Detection(box: box, confidence: result.confidence, label: label, color: self.colors[colorIndex])
                    detections.append(detection)
                }
                let ciContext = CIContext()
                guard let renderedImage = visualizeDetectResults(ciContext: ciContext, detections: detections, pixelBuffer: frame),
                      let pixelBuffer = renderedImage.cgImage?.toCVPixelBuffer()
                else {
                    print("Failed to render image")
                    lastRenderedBuffer = frame
                    continue
                }
                lastRenderedBuffer = pixelBuffer
            }
            self.isRendering = false
            if let buffer = lastRenderedBuffer {
                self.delegate?.videoRendererDidFinishRendering(buffer: buffer)
            }
        }
    }
}
