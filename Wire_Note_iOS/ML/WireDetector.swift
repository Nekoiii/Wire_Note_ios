//
//  WireDetector.swift
//  Wire_Note_iOS
//
//  Created by John Smith on 2024/05/19.
//

import Foundation
import CoreML
import Vision
import UIKit


class WireDetector {
    let ciContext = CIContext()
    let colors:[UIColor] = {
        var colorSet:[UIColor] = []
        for _ in 0...80 {
            let color = UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1)
            colorSet.append(color)
        }
        return colorSet
    }()
    var classes: [String] = []
    lazy var yoloRequest:VNCoreMLRequest! = {
        do {
            let model = try wire_model().model
            guard let classes = model.modelDescription.classLabels as? [String] else {
                fatalError()
            }
            self.classes = classes
            let vnModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: vnModel)
            return request
        } catch let error {
            fatalError("mlmodel error.")
        }
    }()
    

    
    func detection(pixelBuffer: CVPixelBuffer, videoSize: CGSize) -> UIImage? {
        do {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
            try handler.perform([yoloRequest])
            guard let results = yoloRequest.results as? [VNRecognizedObjectObservation] else {
                return nil
            }
            var detections:[Detection] = []
            for result in results {
                let flippedBox = CGRect(x: result.boundingBox.minX, y: 1 - result.boundingBox.maxY, width: result.boundingBox.width, height: result.boundingBox.height)
                let box = VNImageRectForNormalizedRect(flippedBox, Int(videoSize.width), Int(videoSize.height))

                guard let label = result.labels.first?.identifier as? String,
                        let colorIndex = classes.firstIndex(of: label) else {
                        return nil
                }
                let detection = Detection(box: box, confidence: result.confidence, label: label, color: colors[colorIndex])
                detections.append(detection)
            }
            let drawImage = drawRectsOnImage(detections, pixelBuffer)
            return drawImage
        } catch let error {
            return nil
            print(error)
        }
    }
    
    func drawRectsOnImage(_ detections: [Detection], _ pixelBuffer: CVPixelBuffer) -> UIImage? {
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
        
        guard let newImage = cgContext.makeImage() else { return nil }
        return UIImage(ciImage: CIImage(cgImage: newImage))
    }
    
}


struct Detection {
    let box:CGRect
    let confidence:Float
    let label:String?
    let color:UIColor
}
