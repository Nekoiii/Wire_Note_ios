import UIKit
import CoreVideo
import CoreImage
import AVFoundation

extension UIImage {
    convenience init?(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        self.init(cgImage: cgImage)
    }
    
    func pixelBuffer() -> CVPixelBuffer? {
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        context?.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
}

extension CVPixelBuffer {
    func fillPixelBufferFromImage(_ image: UIImage) {
        CVPixelBufferLockBaseAddress(self, [])
        if let cgImage = image.cgImage {
            let pixelData = CVPixelBufferGetBaseAddress(self)
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            guard
                let context = CGContext.init(
                    data: pixelData,
                    width: Int(image.size.width),
                    height: Int(image.size.height),
                    bitsPerComponent: 8,
                    bytesPerRow: CVPixelBufferGetBytesPerRow(self),
                    space: rgbColorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                )
            else {
                assert(false)
                return
            }
            context.draw(cgImage, in: CGRect.init(x: 0, y: 0, width: image.size.width, height: image.size.height))
        }
        CVPixelBufferUnlockBaseAddress(self, [])
    }
}



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

extension CGAffineTransform {
    func videoOrientation() -> UIImage.Orientation {
        if self.a == 0 && self.b == 1.0 && self.c == -1.0 && self.d == 0 {
            return .right
        } else if self.a == 0 && self.b == -1.0 && self.c == 1.0 && self.d == 0 {
            return .left
        } else if self.a == 1.0 && self.b == 0 && self.c == 0 && self.d == 1.0 {
            return .up
        } else if self.a == -1.0 && self.b == 0 && self.c == 0 && self.d == -1.0 {
            return .down
        } else {
            return .up // Default orientation
        }
    }
}

extension UIImage {
    func rotated(by orientation: UIImage.Orientation) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        var transform: CGAffineTransform = .identity

        switch orientation {
        case .up:
            // No rotation needed
            transform = .identity
        case .down:
            // 180 degrees rotation
            transform = CGAffineTransform(translationX: size.width, y: size.height).rotated(by: .pi)
        case .left:
            // 90 degrees counterclockwise
            transform = CGAffineTransform(translationX: 0, y: size.height).rotated(by: -.pi / 2)
        case .right:
            // 90 degrees clockwise
            transform = CGAffineTransform(translationX: size.width, y: 0).rotated(by: .pi / 2)
        case .upMirrored:
            // Horizontal flip
            transform = CGAffineTransform(translationX: size.width, y: 0).scaledBy(x: -1, y: 1)
        case .downMirrored:
            // Vertical flip
            transform = CGAffineTransform(translationX: 0, y: size.height).scaledBy(x: 1, y: -1)
        case .leftMirrored:
            // Vertical flip then 90 degrees counterclockwise
            transform = CGAffineTransform(translationX: size.width, y: size.height).scaledBy(x: -1, y: 1).rotated(by: -.pi / 2)
        case .rightMirrored:
            // Horizontal flip then 90 degrees clockwise
            transform = CGAffineTransform(translationX: size.width, y: size.height).scaledBy(x: 1, y: -1).rotated(by: .pi / 2)
        @unknown default:
            // Default case, no rotation
            transform = .identity
        }

        guard let colorSpace = cgImage.colorSpace,
              let context = CGContext(data: nil,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: cgImage.bitsPerComponent,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: cgImage.bitmapInfo.rawValue) else {
            return nil
        }

        context.concatenate(transform)

        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }

        guard let newCgImage = context.makeImage() else { return nil }

        return UIImage(cgImage: newCgImage)
    }
}
