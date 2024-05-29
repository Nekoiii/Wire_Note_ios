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
            let drawImage = visualizeDetectResults(ciContext:ciContext,detections:detections, pixelBuffer:pixelBuffer)
            return drawImage
        } catch let error {
            print(error)
            return nil
        }
    }
    
    
}


struct Detection {
    let box:CGRect
    let confidence:Float
    let label:String?
    let color:UIColor
}
