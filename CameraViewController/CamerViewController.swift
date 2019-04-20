//
//  CamerViewController.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 4/18/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit
import MobileCoreServices
import Photos
import AssetsLibrary
import AVFoundation

class CameraViewController: UIViewController {
    
    var captureSesssion: AVCaptureSession?
    var cameraOutput: AVCapturePhotoOutput?
    var videoOutput: AVCaptureVideoDataOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    public typealias ImageDidSelectedBlock = (UIImage?, URL?, MediaType) -> Void
    var imageDidSelectedBlock : ImageDidSelectedBlock?
    
    var mediaType: MediaType = .camera
    
    var timer: Timer?
    let imagePickerController = UIImagePickerController()
    
    fileprivate var currentPosition = AVCaptureDevice.Position.back
    
    fileprivate var videoWriter: TimeLapseVideoWriter?
    var isCapturing = false
    let skipFrameSize = 5
    
    private let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
    private let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
    private var lasttimeStamp = CMTimeMake(value: 0, timescale: 0)
    private let recordingQueue = DispatchQueue(label: "com.takecian.RecordingQueue", attributes: [])
    
    var height = 0
    var width = 0
    var seconds: Int = 105
    
    var tempFilePath: URL = {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath: String = "\(documentsDirectory)/video.mp4"
        
        if FileManager.default.fileExists(atPath: filePath) {
            try? FileManager.default.removeItem(atPath: filePath)
        }
        return URL(fileURLWithPath: filePath)
    }()
    
    let buttonCaptureVideo: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.red, for: .normal)
        button.setTitle("Start", for: .normal)
        return button
    }()
    
    let viewPreview: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private func configureCamera() {
        captureSesssion = AVCaptureSession()
        captureSesssion?.sessionPreset = AVCaptureSession.Preset.photo
        cameraOutput = AVCapturePhotoOutput()
        startCamera()
    }
    
    func startCamera(shouldShowBackCamera: Bool = true) {
        
        var device: AVCaptureDevice?
        device = shouldShowBackCamera ? AVCaptureDevice.default(.builtInWideAngleCamera,
                                                                for: AVMediaType.video,
                                                                position: .back) : AVCaptureDevice.default(.builtInWideAngleCamera,
                                                                                                           for: AVMediaType.video,
                                                                                                           position: .front)
        
        guard let captureDevice = device, let input = try? AVCaptureDeviceInput(device: captureDevice), let session = captureSesssion, session.canAddInput(input) else { return }
        
        captureSesssion?.addInput(input)
        guard let output = cameraOutput else { return }
        if session.canAddOutput(output) {
            session.addOutput(output)
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            guard let layer = previewLayer else { return }
            layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            layer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            layer.frame.size.width = UIScreen.main.bounds.width
            layer.frame.size.height = UIScreen.main.bounds.height
            viewPreview.layer.addSublayer(layer)
            captureSesssion?.startRunning()
        }
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(viewPreview)
        viewPreview.g_pinEdges(view: view)
        
        view.addSubview(buttonCaptureVideo)
        
        NSLayoutConstraint.activate([
        buttonCaptureVideo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        buttonCaptureVideo.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        buttonCaptureVideo.addTarget(self, action: #selector(startCamera(_:)), for: .touchUpInside)
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        configureCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        previewLayer = nil
    }
    
    @objc private func startCamera(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            
            let videoCaptureOutput = AVCaptureVideoDataOutput()
            videoCaptureOutput.videoSettings = [((kCVPixelBufferPixelFormatTypeKey as NSString) as String) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
            videoCaptureOutput.alwaysDiscardsLateVideoFrames = true
            
            if let cameraOutput = cameraOutput {
                captureSesssion?.removeOutput(cameraOutput)
            }
            guard let session = captureSesssion else { return }
            if (session.canAddOutput(videoCaptureOutput) == true) {
                session.addOutput(videoCaptureOutput)
            }
            
            let queue = DispatchQueue(label: "com.invasivecode.videoQueue")
            
            videoCaptureOutput.setSampleBufferDelegate(self, queue: queue)
//            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(CameraViewController.didChangeTime), userInfo: nil, repeats: true)
//            buttonMode?.isHidden = true
//            buttonCameraToogle?.isHidden = true
            captureSesssion?.startRunning()
            
            if !isCapturing{
                isCapturing = true
            }
            
        } else {
            stopRecording()
            stop()
        }
    }
    
    func stop() {
        guard isCapturing else { return }
        isCapturing = false
    }
    
    func stopRecording()  {
        timer?.invalidate()
        captureSesssion?.stopRunning()
        view.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.225) { [weak self] in
            self?.viewPreview.alpha = 0.0
        }
    }
    
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
}

extension CameraViewController{
    
    class TimeLapseVideoWriter : NSObject {
        var fileWriter: AVAssetWriter?
        var videoInput: AVAssetWriterInput?
        var audioInput: AVAssetWriterInput?
        
        init(fileUrl:URL, height:Int, width:Int){
            fileWriter = try? AVAssetWriter(outputURL: fileUrl, fileType: AVFileType.mov)
            
            let videoOutputSettings: Dictionary<String, AnyObject> = [
                AVVideoCodecKey : AVVideoCodecH264 as AnyObject,
                AVVideoWidthKey : width as AnyObject,
                AVVideoHeightKey : height as AnyObject
            ]
            let videoinput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
            videoinput.expectsMediaDataInRealTime = true
            videoinput.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi)/2)
            videoInput = videoinput
            
            fileWriter?.add(videoinput)
            
        }
        
        func write(_ sample: CMSampleBuffer, isVideo: Bool){
            if CMSampleBufferDataIsReady(sample) {
                if fileWriter?.status == AVAssetWriter.Status.unknown {
                    let startTime = CMSampleBufferGetPresentationTimeStamp(sample)
                    fileWriter?.startWriting()
                    fileWriter?.startSession(atSourceTime: startTime)
                }
                if fileWriter?.status == AVAssetWriter.Status.failed {
                    return
                }
                if (videoInput?.isReadyForMoreMediaData ?? false) {
                    videoInput?.append(sample)
                }
                
            }
        }
        
        func finish(_ callback: @escaping () -> Void){
            fileWriter?.finishWriting(completionHandler: callback)
        }
    }
}

extension CameraViewController {
    
    enum MediaType {
        case camera
        case video
        case gallery
    }
}
