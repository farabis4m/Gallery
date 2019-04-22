//
//  CameraManager.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 4/22/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit
import AVFoundation

class CameraManager: NSObject {
    
    private var captureSession: AVCaptureSession?
    
    private var currentCameraPosition: CameraPosition?
    
    private var frontCamera: AVCaptureDevice?
    private var frontCameraInput: AVCaptureDeviceInput?
    
    private var photoOutput: AVCapturePhotoOutput?
    
    private var rearCamera: AVCaptureDevice?
    private var rearCameraInput: AVCaptureDeviceInput?
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var flashMode = AVCaptureDevice.FlashMode.off
    
    private var photoCaptureCompletionBlock: PhotoCaptureCompletionBlock?
    
    typealias PhotoCaptureCompletionBlock = ((UIImage?, Error?) -> Void)
    
    var displayView: UIView
    
    init(displayView: UIView) {
        self.displayView = displayView
        super.init()
        self.initiateCamera()
    }
    
    // call this function from outside the manager.
    func captureImage(completion: @escaping (UIImage?, Error?) -> Void) {
        guard let captureSession = captureSession, captureSession.isRunning else { completion(nil, CameraError.captureSessionIsMissing); return }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        
        photoOutput?.capturePhoto(with: settings, delegate: self)
        photoCaptureCompletionBlock = completion
    }
}

private extension CameraManager {
    
    private func printError(error: Error?) {
        guard let error = error else { return }
        if let err = error as? CameraError {
            print(err.message)
        } else {
            print(error.localizedDescription)
        }
    }
    
    private func displayPreview() {
        do {
            try self.displayPreview(on: displayView)
        } catch {
            printError(error: error)
        }
    }
    
    func initiateCamera() {
        setupCamera { [weak self] (error) in
            guard error == nil else {
                self?.printError(error: error)
                return
            }
            self?.displayPreview()
        }
    }
}

private extension CameraManager {
    
    typealias CameraCompletion = (Error?) -> Void
    
    func setupCamera(completion: @escaping CameraCompletion) {
        DispatchQueue(label: "prepareCamera").async { [weak self] in
            guard let welf = self else { return }
            do {
                welf.createCaptureSession()
                try welf.configureCaptureDevices()
                try welf.configureDeviceInputs()
                try welf.configurePhotoOutput()
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    
    func createCaptureSession() {
        captureSession = AVCaptureSession()
    }
    
    func configureCaptureDevices() throws {
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        let cameras = session.devices.compactMap { $0 }
        guard !cameras.isEmpty else { throw CameraError.noCamerasAvailable }
        for camera in cameras {
            switch camera.position {
            case .front:
                frontCamera = camera
            case .back:
                rearCamera = camera
                try camera.lockForConfiguration()
                camera.focusMode = .continuousAutoFocus
                camera.unlockForConfiguration()
            case .unspecified:
                throw CameraError.noCamerasAvailable
            }
        }
    }
    
    func configureDeviceInputs() throws {
        guard let captureSession = captureSession else { throw CameraError.captureSessionIsMissing }
        
        guard let rearCamera = rearCamera else { throw CameraError.noCamerasAvailable }
        rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
        if captureSession.canAddInput(self.rearCameraInput!) { captureSession.addInput(rearCameraInput!) }
        currentCameraPosition = .rear
    }
    
    func configurePhotoOutput() throws {
        guard let captureSession = captureSession else { throw CameraError.captureSessionIsMissing }
        photoOutput = AVCapturePhotoOutput()
        if #available(iOS 11.0, *) {
            photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
        } else {
            // Fallback on earlier versions
            photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])], completionHandler: nil)
        }
        if captureSession.canAddOutput(photoOutput!) { captureSession.addOutput(photoOutput!) }
        captureSession.startRunning()
    }
}

private extension CameraManager {
    
    func displayPreview(on view: UIView) throws {
        guard let captureSession = captureSession, captureSession.isRunning else { throw CameraError.captureSessionIsMissing }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer?.connection?.videoOrientation = .landscapeRight
        
        view.layer.insertSublayer(previewLayer!, at: 0)
        previewLayer?.frame = view.bounds
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            return
        }
        photoCaptureCompletionBlock?(image, nil)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                     resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        // Make sure we get some photo sample buffer
        guard error == nil, let photoSampleBuffer = photoSampleBuffer else { return }
        
        // Convert photo same buffer to a jpeg image data by using // AVCapturePhotoOutput
        guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer), let image = UIImage(data: imageData) else { return }
        
        photoCaptureCompletionBlock?(image, nil)
    }
}

extension CameraManager {
    
    enum CameraPosition {
        case front
        case rear
    }
    
    enum CameraError: String, Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
        
        var message: String {
            return rawValue
        }
    }
}
