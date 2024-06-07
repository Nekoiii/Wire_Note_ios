import AVFoundation
import UIKit

extension AVAssetWriterInputPixelBufferAdaptor {
    func appendPixelBufferForImage(_ image: UIImage, presentationTime: CMTime) -> Bool {
        var appendSucceeded = false
        autoreleasepool {
            guard let pixelBufferPool = self.pixelBufferPool else {
                NSLog("appendPixelBufferForImage: ERROR - missing pixelBufferPool") // writer can have error:  writer.error=\(String(describing: self.writer.error))
                return
            }
            let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
            let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                kCFAllocatorDefault,
                pixelBufferPool,
                pixelBufferPointer
            )
            if let pixelBuffer = pixelBufferPointer.pointee, status == 0 {
                pixelBuffer.fillPixelBufferFromImage(image)
                appendSucceeded = self.append(pixelBuffer, withPresentationTime: presentationTime)
                if !appendSucceeded {
                    // If a result of NO is returned, clients can check the value of AVAssetWriter.status to determine whether the writing operation completed, failed, or was cancelled.  If the status is AVAssetWriterStatusFailed, AVAsset.error will contain an instance of NSError that describes the failure.
                    NSLog("VideoWriter appendPixelBufferForImage: ERROR appending")
                }
                pixelBufferPointer.deinitialize(count: 1)
            } else {
                NSLog("VideoWriter appendPixelBufferForImage: ERROR - Failed to allocate pixel buffer from pool, status=\(status)") // -6680 = kCVReturnInvalidPixelFormat
            }
            pixelBufferPointer.deallocate()
        }
        return appendSucceeded
    }
}
