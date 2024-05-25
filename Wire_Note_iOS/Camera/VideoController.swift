//
//  VideoController.swift
//  pmv
//
//  Created by John Smith on 2024/02/16.
//

import Foundation
import AVFoundation
import UIKit
import CoreML
import Vision
import SwiftUI

private let FREQUENCY_OF_PREDICTION = 10

typealias onFrameCaptured = (UIImage) -> Void

class VideoController: ObservableObject, VideoCaptureDelegate {
    @Published var precessTime: TimeInterval = 0
    @Published var currentImage: UIImage?
    @Published var clothing: LocalizedStringKey?
    var clothingKey: String?
    private let videoCapture = VideoCapture()
    private var currentFrame: CGImage?
    private let wireDetector = WireDetector()
    
    var onFrameCaptured: onFrameCaptured?
    
    init() {
        setupAndBeginCapturingVideoFrames()
    }
    
    private func setupAndBeginCapturingVideoFrames() {
        videoCapture.setUpAVCapture { error in
            if let error = error {
                print("Failed to setup camera with error \(error)")
                return
            }
            self.videoCapture.delegate = self
            self.videoCapture.startCapturing()
        }
    }
    
    
    func flipCamera() {
        videoCapture.flipCamera { error in
            if let error = error {
                print("Failed to flip camera with error \(error)")
            }
        }
    }
    
    
    func videoCapture(sampleBuffer: CVPixelBuffer, videoSize: CGSize) {
        guard let image = self.wireDetector.detection(pixelBuffer: sampleBuffer, videoSize: videoSize)
        else {
            print("Captured image is null")
            return
        }
        onFrameCaptured?(image)
    }
    
}
