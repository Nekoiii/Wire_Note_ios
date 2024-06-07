/*
 See LICENSE folder for this sample’s licensing information.

 Abstract:
 The implementation of a utility class that facilitates frame captures from the device
  camera.
 */

import AVFoundation
import CoreVideo
import UIKit
import VideoToolbox

protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(sampleBuffer: CVPixelBuffer, videoSize: CGSize)
}

protocol VideoCaptureSampleBufferDelegate: AnyObject {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame image: CMSampleBuffer?)
}

/// - Tag: VideoCapture
class VideoCapture: NSObject {
    enum VideoCaptureError: Error {
        case captureSessionIsMissing
        case invalidInput
        case invalidOutput
        case unknown
    }

    /// The delegate to receive the captured frames.
    weak var delegate: VideoCaptureDelegate?

    weak var sampleBufferDelegate: VideoCaptureSampleBufferDelegate?

    /// A capture session used to coordinate the flow of data from input devices to capture outputs.
    let captureSession = AVCaptureSession()

    /// A capture output that records video and provides access to video frames. Captured frames are passed to the
    /// delegate via the `captureOutput()` method.
    let videoOutput = AVCaptureVideoDataOutput()

    /// The current camera's position.
    var cameraPostion = AVCaptureDevice.Position.back

    var curDevice: AVCaptureDevice?

    var curWidth: Int32 = 0
    var curHeight: Int32 = 0

    var isSupportWildAngel = false
    var isNeedWildAngel = false

    /// The dispatch queue responsible for processing camera set up and frame capture.
    private let sessionQueue = DispatchQueue(
        label: "com.example.apple-samplecode.estimating-human-pose-with-posenet.sessionqueue")

    /// Toggles between the front and back camera.
    public func flipCamera(completion: @escaping (Error?) -> Void) {
        sessionQueue.async {
            do {
                self.cameraPostion = self.cameraPostion == .back ? .front : .back

                // Indicate the start of a set of configuration changes to the capture session.
                self.captureSession.beginConfiguration()

                try self.setCaptureSessionInput()
                try self.setCaptureSessionOutput()

                // Commit configuration changes.
                self.captureSession.commitConfiguration()

                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    func checkCameraPermission() -> Bool {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch authStatus {
        case .authorized:
            // 用户已经授权摄像头权限
            print("Camera access authorized")
            // 执行你的摄像头操作
            return true
        case .denied, .restricted:
            // 用户已经拒绝或限制了摄像头权限
            print("Camera access denied")
            // 提示用户打开摄像头权限的相关操作
            return false
        case .notDetermined:
            // 摄像头权限尚未确定，系统会在第一次使用时触发权限询问框
            print("Camera access not determined yet")
        // 不需要执行额外操作，等待用户的响应即可
        @unknown default:
            // 处理未知的授权状态
            break
        }
        return true
    }

    public func isMirrored() -> Bool {
        return cameraPostion == .front
    }

    /// Asynchronously sets up the capture session.
    ///
    /// - parameters:
    ///     - completion: Handler called once the camera is set up (or fails).
    public func setUpAVCapture(completion: @escaping (Error?) -> Void) {
        sessionQueue.async {
            do {
                try self.setUpAVCapture()
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }

    private func setUpAVCapture() throws {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }

        captureSession.beginConfiguration()

        captureSession.sessionPreset = .hd1280x720

        try setCaptureSessionInput()

        try setCaptureSessionOutput()

        captureSession.commitConfiguration()
    }

    public func refreshInput() throws {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        captureSession.beginConfiguration()
        try setCaptureSessionInput()
        try setCaptureSessionOutput()
        captureSession.commitConfiguration()
    }

    public func enableWildAngle(enable: Bool) {
        isNeedWildAngel = enable
        sessionQueue.async {
            do {
                try self.refreshInput()
            } catch {
                print("enableWildAngle:\(error)")
            }
        }
    }

    func checkSupportWideLens() -> Bool {
        let captureDevice = AVCaptureDevice.default(
            .builtInUltraWideCamera,
            for: AVMediaType.video,
            position: .back
        )
        if captureDevice == nil {
            return false
        }
        return true
    }

    private func setCaptureSessionInput() throws {
        // Use the default capture device to obtain access to the physical device
        // and associated properties.
        var captureDevice: AVCaptureDevice? = nil

        if isNeedWildAngel {
            captureDevice = AVCaptureDevice.default(
                .builtInUltraWideCamera,
                for: AVMediaType.video,
                position: cameraPostion
            )
        }

        if captureDevice == nil {
            captureDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: AVMediaType.video,
                position: cameraPostion
            )
        }

        // Remove any existing inputs.
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }

        guard let captureDevice = captureDevice else {
            throw VideoCaptureError.invalidInput
        }

        curDevice = captureDevice

        // 检查是否支持调整焦距
        guard let curDevice = curDevice else {
            //     print("不支持调整焦距")
            return
        }
        //   if curDevice.isFocusModeSupported(.autoFocus) {
        // 获取当前焦距
        let currentZoomFactor = curDevice.videoZoomFactor
        print("当前焦距：\(currentZoomFactor)")
        // } else {
        //    print("不支持调整焦距")
        // }

        // Create an instance of AVCaptureDeviceInput to capture the data from
        // the capture device.
        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            throw VideoCaptureError.invalidInput
        }

        guard captureSession.canAddInput(videoInput) else {
            throw VideoCaptureError.invalidInput
        }

        captureSession.addInput(videoInput)
    }

    private func setCaptureSessionOutput() throws {
        // Remove any previous outputs.
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }

        // Set the pixel type.
        let settings: [String: Any] = [
            String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA,
        ]

        videoOutput.videoSettings = settings

        // Discard newer frames that arrive while the dispatch queue is already busy with
        // an older frame.
        videoOutput.alwaysDiscardsLateVideoFrames = true

        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)

        guard captureSession.canAddOutput(videoOutput) else {
            throw VideoCaptureError.invalidOutput
        }

        captureSession.addOutput(videoOutput)

        // Update the video orientation
        if let connection = videoOutput.connection(with: .video),
           connection.isVideoOrientationSupported
        {
            connection.videoOrientation =
                AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation)
            connection.isVideoMirrored = cameraPostion == .front

            // Inverse the landscape orientation to force the image in the upward
            // orientation.
            if connection.videoOrientation == .landscapeLeft {
                connection.videoOrientation = .landscapeRight
            } else if connection.videoOrientation == .landscapeRight {
                connection.videoOrientation = .landscapeLeft
            }
//            let dimensions = connection.videoDimensions
//                  curWidth = dimensions.width
//                  curHeight = dimensions.height
        }
        // connection?.videoPreviewLayer?.frame.width
    }

    public func updateOrientation() {
        // Update the video orientation
        if let connection = videoOutput.connection(with: .video),
           connection.isVideoOrientationSupported
        {
            connection.videoOrientation =
                AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation)
            connection.isVideoMirrored = cameraPostion == .front

            // Inverse the landscape orientation to force the image in the upward
            // orientation.
            if connection.videoOrientation == .landscapeLeft {
                connection.videoOrientation = .landscapeRight
            } else if connection.videoOrientation == .landscapeRight {
                connection.videoOrientation = .landscapeLeft
            }
//            let inputPort = connection.inputPorts.first( where:{ $0.mediaType == .video })
//            if(inputPort != nil && inputPort?.formatDescription != nil) {
//                let dimensions = CMVideoFormatDescriptionGetDimensions(inputPort!.formatDescription!)
//                  curWidth = dimensions.width
//                  curHeight = dimensions.height
//                print("\(curWidth) \(curHeight)")
//            }
        }
    }

    /// Begin capturing frames.
    ///
    /// - Note: This is performed off the main thread as starting a capture session can be time-consuming.
    ///
    /// - parameters:
    ///     - completionHandler: Handler called once the session has started running.
    public func startCapturing(completion _: (() -> Void)? = nil) {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                // Invoke the startRunning method of the captureSession to start the
                // flow of data from the inputs to the outputs.
                self.captureSession.startRunning()
            }
        }
    }

    /// End capturing frames
    ///
    /// - Note: This is performed off the main thread, as stopping a capture session can be time-consuming.
    ///
    /// - parameters:
    ///     - completionHandler: Handler called once the session has stopping running.
    public func stopCapturing(completion completionHandler: (() -> Void)? = nil) {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }

            if let completionHandler = completionHandler {
                DispatchQueue.main.async {
                    completionHandler()
                }
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from _: AVCaptureConnection)
    {
        guard let delegate = delegate else { return }
        guard let width = sampleBuffer.formatDescription?.dimensions.width,
              let height = sampleBuffer.formatDescription?.dimensions.height
        else {
            fatalError()
        }
        let videoSize = CGSize(width: CGFloat(width), height: CGFloat(height))
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        delegate.videoCapture(sampleBuffer: pixelBuffer, videoSize: videoSize)
    }
}
