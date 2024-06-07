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
