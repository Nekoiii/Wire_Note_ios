import UIKit
import AVFoundation

extension CVPixelBuffer {
    // Convert CVPixelBuffer to CMSampleBuffer
    func toCMSampleBuffer() -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        var formatDescription: CMVideoFormatDescription?
        
        let status = CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: self,
            formatDescriptionOut: &formatDescription
        )
        
        guard status == kCVReturnSuccess, let videoFormatDescription = formatDescription else {
            return nil
        }
        
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime.invalid,
            presentationTimeStamp: CMTime.zero,
            decodeTimeStamp: CMTime.invalid
        )
        
        let sampleBufferStatus = CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: self,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: videoFormatDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        
        guard sampleBufferStatus == noErr else {
            return nil
        }
        
        return sampleBuffer
    }
    
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
