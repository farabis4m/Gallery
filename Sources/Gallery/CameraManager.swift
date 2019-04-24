//
//  CameraManager.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 4/24/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import AVFoundation
import AVKit


class CameraManager: NSObject {
    
    typealias PhotoCaptureCompletionBlock = ((UIImage?, Error?) -> Void)
    var photoCaptureCompletionBlock: PhotoCaptureCompletionBlock?
    
    typealias VideoCaptureCompletionBlock = ((URL?, Error?) -> Void)
    var videoCaptureCompletionBlock: VideoCaptureCompletionBlock?

    typealias VideoCaptureStartedBlock = (() -> Void)
    var videoCaptureStartedBlock: VideoCaptureStartedBlock?

    
    private var tempFilePath: URL = {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath: String = "\(documentsDirectory)/video.mp4"
        if FileManager.default.fileExists(atPath: filePath) {
            try? FileManager.default.removeItem(atPath: filePath)
        }
        return URL(fileURLWithPath: filePath)
    }()
    
    private let captureSession = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var activeInput: AVCaptureDeviceInput?
    private var cameraOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var viewPreview: UIView
    
    
    init(previewView: UIView) {
        self.viewPreview = previewView
        super.init()
        initiateCamera()
    }
    
    func updateFrame() {
        previewLayer?.frame = viewPreview.bounds
    }
}


// Initiating camera
private extension CameraManager {
    
    private func initiateCamera() {
        if setupSession() {
            setupPreview()
            startSession()
        }
    }
    
    func setupSession() -> Bool {
        
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        
        // Setup Camera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return  false }
        
        do {
            
            let input = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            }
        } catch {
            print("Error setting device video input: \(error)")
            return false
        }
        
        // Setup Microphone
        let microphone = AVCaptureDevice.default(for: AVMediaType.audio)!
        
        do {
            let micInput = try AVCaptureDeviceInput(device: microphone)
            if captureSession.canAddInput(micInput) {
                captureSession.addInput(micInput)
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return false
        }
        
        cameraOutput = AVCapturePhotoOutput()
        
        if let output = cameraOutput, captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        
        // Movie output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }
        
        return true
    }
    
    func setupPreview() {
        // Configure previewLayer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = viewPreview.bounds
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        if let layer = previewLayer {
            viewPreview.layer.addSublayer(layer)
        }
    }
    
    func startSession() {
        
        if !captureSession.isRunning {
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func videoQueue() -> DispatchQueue {
        return DispatchQueue.main
    }
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        
        return orientation
    }
    
}

private extension CameraManager {
    
    func startVideoRecording() {
        let connection = movieOutput.connection(with: AVMediaType.video)
        
        if (connection?.isVideoOrientationSupported)! {
            connection?.videoOrientation = currentVideoOrientation()
        }
        
        if (connection?.isVideoStabilizationSupported)! {
            connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
        }
        
        guard let device = activeInput?.device else { return }
        
        if (device.isSmoothAutoFocusSupported) {
            
            do {
                try device.lockForConfiguration()
                device.isSmoothAutoFocusEnabled = false
                device.unlockForConfiguration()
            } catch {
                print("Error setting configuration: \(error)")
            }
            
        }
        
        movieOutput.startRecording(to: tempFilePath, recordingDelegate: self)
    }
    
    func stopVideoRecording() {
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
        }
    }
    
    func takePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isHighResolutionPhotoEnabled = false
        
        if let firstAvailablePreviewPhotoPixelFormatTypes = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: firstAvailablePreviewPhotoPixelFormatTypes]
        }
        cameraOutput?.capturePhoto(with: photoSettings, delegate: self)
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate, AVCapturePhotoCaptureDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        videoCaptureStartedBlock?()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else {
            videoCaptureCompletionBlock?(nil, error)
            return
        }
        videoCaptureCompletionBlock?(outputFileURL, nil)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() , let image = UIImage(data: imageData) else {
            photoCaptureCompletionBlock?(nil, error)
            return
        }
        photoCaptureCompletionBlock?(image, nil)
    }
}

// MARK: outside functions to capture photo and video
extension CameraManager {
    
    func capturePhoto() {
        takePhoto()
    }
    
    func captureVideo() {
        guard !movieOutput.isRecording else {
            stopVideoRecording()
            return
        }
        startVideoRecording()
    }
}
