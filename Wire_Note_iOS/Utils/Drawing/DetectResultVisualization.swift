//
//  DetectResultVisualization.swift
//  Wire_Note_iOS
//
//  Created by 猫草 on 2024/05/26.
//

import UIKit
import Vision

func drawRectsOnImage(ciContext:CIContext,detections: [Detection],pixelBuffer: CVPixelBuffer) -> UIImage? {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent)!
    let size = ciImage.extent.size
    guard let cgContext = CGContext(data: nil,
                                    width: Int(size.width),
                                    height: Int(size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: 4 * Int(size.width),
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
    cgContext.draw(cgImage, in: CGRect(origin: .zero, size: size))
    for detection in detections {
        DrawBBox(detection,cgContext,size)
        
    }
    
    guard let newImage = cgContext.makeImage() else { return nil }
    return UIImage(cgImage: newImage)
}

func DrawBBox(_ detection: Detection,_ cgContext:CGContext,_ size:CGSize){
    let invertedBox = CGRect(x: detection.box.minX, y: size.height - detection.box.maxY, width: detection.box.width, height: detection.box.height)
    if let labelText = detection.label {
        cgContext.textMatrix = .identity
        
        let text = "\(labelText) : \(round(detection.confidence*100))"
        
        let textRect  = CGRect(x: invertedBox.minX + size.width * 0.01, y: invertedBox.minY - size.width * 0.01, width: invertedBox.width, height: invertedBox.height)
        let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        
        let textFontAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: textRect.width * 0.1, weight: .bold),
            NSAttributedString.Key.foregroundColor: detection.color,
            NSAttributedString.Key.paragraphStyle: textStyle
        ]
        
        cgContext.saveGState()
        defer { cgContext.restoreGState() }
        let astr = NSAttributedString(string: text, attributes: textFontAttributes)
        let setter = CTFramesetterCreateWithAttributedString(astr)
        let path = CGPath(rect: textRect, transform: nil)
        
        let frame = CTFramesetterCreateFrame(setter, CFRange(), path, nil)
        cgContext.textMatrix = CGAffineTransform.identity
        CTFrameDraw(frame, cgContext)
        
        cgContext.setStrokeColor(detection.color.cgColor)
        cgContext.setLineWidth(9)
        cgContext.stroke(invertedBox)
    }
}
func drawNote(){
    
    
}
