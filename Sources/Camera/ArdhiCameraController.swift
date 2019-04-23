//
//  ArdhiCameraController.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 4/21/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit
import AVFoundation

class ArdhiCameraController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var captureSesssion: AVCaptureSession?
    var cameraOutput: AVCapturePhotoOutput?
    var videoOutput: AVCaptureVideoDataOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    public typealias ImageDidSelectedBlock = (UIImage?, URL?, MediaType) -> Void
    var imageDidSelectedBlock : ImageDidSelectedBlock?
    
    var mediaType: MediaType = .camera {
        didSet {
            viewBottom.mediaType = mediaType
        }
    }
    
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

    lazy var viewBottom = makeBottomView()
    private lazy var viewPreview = makePreviewView()
    private lazy var labelTime = makeTimeLabel()
    
    var cart = Cart()
    
    convenience init(cart: Cart) {
        self.init(nibName: nil, bundle: nil)
        self.cart = cart
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(viewBottom)
        viewBottom.g_pin(on: .left)
        viewBottom.g_pin(on: .right)
        viewBottom.g_pin(on: .bottom)
        viewBottom.g_pin(height: 101)
        
        view.addSubview(viewPreview)
        viewPreview.g_pin(on: .left)
        viewPreview.g_pin(on: .top)
        viewPreview.g_pin(on: .right)
        viewPreview.g_pin(on: .bottom, view: viewBottom, on: .top)
        setupCameraActions()
        
        view.addSubview(labelTime)
        labelTime.g_pinCenter()
        
        view.addSubview(imageView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = viewPreview.bounds
    }
    
    @objc func didChangeTime() {
        seconds -= 1
        let second = String(format: "%02d", (seconds % 3600) % 60)
        let minute = String(format: "%02d",(seconds % 3600) / 60)
        if (Int(minute) ?? 0) <= 0 && (Int(second) ?? 0)  <= 0 {
            stopRecording()
            stop()
        }
        let time = "\(minute):\(second)"
        labelTime.text = time
    }
    
    private func configureCamera() {
        
        setUpVideoScreen(shouldHideCameraImage:false)
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
//            layer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
             viewPreview.layer.addSublayer(layer)
            layer.frame = viewPreview.bounds
            captureSesssion?.startRunning()
        }
    }
    
    func deviceWithMediaTypeWithPosition(_ mediaType: String, position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
        let deviceDescoverySession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],mediaType: AVMediaType(rawValue: mediaType),position: AVCaptureDevice.Position.unspecified)
        
        for device in deviceDescoverySession.devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    func addVideoInput(_ position: AVCaptureDevice.Position) {
        
        guard let device: AVCaptureDevice = deviceWithMediaTypeWithPosition((AVMediaType.video as NSString) as String, position: position) else { return }
        guard let audioDevice: AVCaptureDevice = AVCaptureDevice.default(for: AVMediaType.audio), let session = captureSesssion else { return }
        guard let audioInput = try? AVCaptureDeviceInput(device:audioDevice) else { return }
        if session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        if session.canAddInput(input) {
            session.addInput(input)
        }
    }
    
    func stopRecording()  {
        timer?.invalidate()
        labelTime.text = nil
        captureSesssion?.stopRunning()
        view.isUserInteractionEnabled = false
        
//        UIView.animate(withDuration: 0.225) { [weak self] in
//            self?.viewPreview.alpha = 0.0
//        }
    }
    
    func resumeRecording() {
        captureSesssion?.startRunning()
        view.isUserInteractionEnabled = true
        
        UIView.animate(withDuration: 0.225) { [weak self] in
            self?.viewPreview.alpha = 1.0
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ArdhiCameraController.didChangeTime), userInfo: nil, repeats: true)
        
    }
    
    func toogleInput(shouldShowBackCamera: Bool = false) {
        captureSesssion?.beginConfiguration()
        for input in captureSesssion?.inputs ?? [] {
            captureSesssion?.removeInput(input)
        }
        
        captureSesssion = AVCaptureSession()
        captureSesssion?.sessionPreset = AVCaptureSession.Preset.photo
        cameraOutput = AVCapturePhotoOutput()
        
        startCamera(shouldShowBackCamera: shouldShowBackCamera)
    }
    
    func setUpVideoScreen(shouldHideCameraImage:Bool)  {
        //        buttonCaptureImage?.isHidden = shouldHideCameraImage
        //        buttonCaptureVideo?.isHidden = !shouldHideCameraImage
        //        labelTime?.isHidden          = !shouldHideCameraImage
    }
    
    func stop(){
        guard isCapturing else { return }
        isCapturing = false
        DispatchQueue.main.async { [weak self] in
            self?.viewBottom.isRecording = false
            self?.configureCamera()
            self?.videoWriter?.finish { [weak self]  in
                guard let welf = self else { return }
                welf.videoWriter = nil
                welf.cart.url = welf.tempFilePath
                DispatchQueue.main.async {
                    EventHub.shared.capturedVideo?()
                }
            }
        }
    }
    
    
    
    fileprivate func setTimeStamp(_ sample: CMSampleBuffer, newTime: CMTime) -> CMSampleBuffer? {
        var count: CMItemCount = 0
        CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: 0, arrayToFill: nil, entriesNeededOut: &count)
        var info = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: CMTimeMake(value: 0, timescale: 0), presentationTimeStamp: CMTimeMake(value: 0, timescale: 0), decodeTimeStamp: CMTimeMake(value: 0, timescale: 0)), count: count)
        CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: count, arrayToFill: &info, entriesNeededOut: &count)
        
        for i in 0..<count {
            info[i].decodeTimeStamp = newTime
            info[i].presentationTimeStamp = newTime
        }
        
        var out: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(allocator: nil, sampleBuffer: sample, sampleTimingEntryCount: count, sampleTimingArray: &info, sampleBufferOut: &out)
        return out
    }
}

extension ArdhiCameraController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    // callBack from video capture
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isCapturing else { return }
        
        let isVideo = videoOutput != nil
        
        if videoWriter == nil && !isVideo {
            let fileManager = FileManager()
            if fileManager.fileExists(atPath: tempFilePath.absoluteString) {
                try? fileManager.removeItem(atPath: tempFilePath.absoluteString)
            }
            
            videoWriter = TimeLapseVideoWriter(fileUrl: tempFilePath, height: 300, width: 300)
        }
        
        var buffer = sampleBuffer
        if lasttimeStamp.value == 0 {
            lasttimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        } else {
            lasttimeStamp = CMTimeAdd(lasttimeStamp, CMTimeMake(value: 1, timescale: 30))
            guard let samplebuffer = setTimeStamp(sampleBuffer, newTime: lasttimeStamp) else { return }
            buffer = samplebuffer
        }
        videoWriter?.write(buffer, isVideo: isVideo)
    }
    
    
    
    // callBack from take picture
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,  didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,  previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings:  AVCaptureResolvedPhotoSettings, bracketSettings:   AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        // Make sure we get some photo sample buffer
        guard error == nil, let photoSampleBuffer = photoSampleBuffer else { return }
        
        // Convert photo same buffer to a jpeg image data by using // AVCapturePhotoOutput
        guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer), let image = UIImage(data: imageData) else {
            viewBottom.mode = .enabled
            return
        }
        cart.image = image
        EventHub.shared.capturedImage?()
    }
    
    
}


private extension ArdhiCameraController {
    
    func makePreviewView() -> UIView {
        let view = UIView()
        return view
    }
    
    func makeBottomView() -> CameraBottomView {
        let view = CameraBottomView()
        return view
    }
    
    func makeTimeLabel() -> UILabel {
        let lbl = UILabel()
        return lbl
    }
}

private extension ArdhiCameraController {
    
    func setupCameraActions() {
        
        viewBottom.didTapbuttonFlash = { [unowned self] sender in
            print("flash tappeed")
        }
        
        viewBottom.didTapCamera = { [unowned self] sender in
            self.capturePicture()
        }
        
        viewBottom.didTapCaptureVideo = { [unowned self] sender in
            self.captureVideo(sender)
        }
        
        viewBottom.didTapToggleCamera = { [unowned self] sender in
            print("toggle tapped")
        }
    }
}

private extension ArdhiCameraController {
    
    func capturePicture() {
        viewBottom.mode = .disabled
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first
        let previewFormat: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType as Any,
            kCVPixelBufferWidthKey as String: 160,
            kCVPixelBufferHeightKey as String: 160
        ]
        settings.previewPhotoFormat = previewFormat
        cameraOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    func captureVideo(_ sender: UIButton) {
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
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ArdhiCameraController.didChangeTime), userInfo: nil, repeats: true)
            viewBottom.isRecording = true
            captureSesssion?.startRunning()
            
            if !isCapturing{
                isCapturing = true
            }
            
        } else {
            stopRecording()
            stop()
        }
    }
}

extension ArdhiCameraController: PageAware {
    func pageDidShow() {
        configureCamera()
    }
}

extension ArdhiCameraController {
    enum MediaType {
        case camera
        case video
        case gallery
    }
}


extension ArdhiCameraController {
    
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


extension ArdhiCameraController {
    // This method you can use somewhere you need to know camera permission   state
    func checkCameraPermission() {
        
        let cameraPermissionStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch cameraPermissionStatus {
            
        case .denied:
            print("denied")
            DispatchQueue.main.async() {
                
                //                AlertViewController.show(from: self, with: .cameraPermission, cancelHandler: { [weak self] (alertView) in
                //                    alertView.dismissController()
                //                    self?.dismissController()
                //
                //                    }, completionHandler: {[weak self] (alertView) in
                //                        alertView.dismissController()
                //
                //                        // go to setting to enable camera
                //                        guard let settingsURL = NSURL(string: UIApplication.openSettingsURLString) as URL? else { return }
                //                        UIApplication.shared.open(settingsURL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                //
                //                        self?.dismissController()
                //
                //                })
            }
            
        case .restricted:
            print("restricted")
            DispatchQueue.main.async() { [weak self] in
                //                self?.dismissController()
            }
            
        case .authorized:
            configureCamera()
            
        default:
            configureCamera()
            
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { [weak self]
                (granted :Bool) -> Void in
                
                if granted {
                }
                else {
                    
                    // dismiss if not permitted
                    DispatchQueue.main.async() { [weak self] in
                        self?.dismissController()
                    }
                }
            }
        }
    }
}

extension UIViewController {
    func dismissController() {
        dismiss(animated: true)
    }
}
