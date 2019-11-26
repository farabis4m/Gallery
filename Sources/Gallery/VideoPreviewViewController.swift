//
//  VideoPreviewViewController.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 5/26/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit
import Photos
import AVKit

class VideoPreviewController: UIViewController {
    
    enum Mode {
        case url(url: URL)
        case asset(asset: PHAsset)
    }
    
    var mode: Mode?
    
    private lazy var topView = makeTopView()
    private lazy var buttonPreview = makePreviewButton()
    private lazy var imageView = makeImageView()
    private var previewImage: UIImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let btn = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(closeButtonTapped))
        navigationItem.leftBarButtonItem = btn
        setupViews()
        imageView.image = previewImage
        
        topView.didTapRight = { [weak self] in
            self?.passVideo()
        }
    }
    
    func passVideo() {
        guard let mode = mode else { return }
        switch mode {
        case .asset(let asset):
            asset.getURL { [weak self] url in
                guard let welf = self else { return }
                welf.selected(url: welf.copyToURl(url: url))
            }
        case .url(let url):
            selected(url: url)
        }
    }
    
 
    
    private var tempFilePath: URL = {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as NSString
        let filePath: String = documentsDirectory.appendingPathComponent(GalleryConfig.shared.videoFileName)
        if FileManager.default.fileExists(atPath: filePath) {
            try? FileManager.default.removeItem(atPath: filePath)
        }
        return URL(fileURLWithPath: filePath)
    }()
    
    func copyToURl(url: URL?) -> URL? {
        guard let url = url else { return nil }
        return FileManager.default.secureCopyItem(at: url, to: tempFilePath)
    }
    
    func selected(url: URL?) {
        dismiss(animated: true, completion: nil)
        DispatchQueue.main.async { [weak self] in
            guard let welf = self else { return }
            EventHub.shared.videoUrl?(url, welf.previewImage)
        }
    }
    
    @objc
    func didTapVideoPlayer() {
        guard let mode = mode else { return }
        var player: AVPlayer?
        switch mode {
        case .asset(let asset):
            asset.getURL { (url) in
                guard let url = url else { return }
                player = AVPlayer(url: url)
                guard let avplayer = player else { return }
                self.playVideo(player: avplayer)
            }
        case .url(let url):
            player = AVPlayer(url: url)
            guard let avplayer = player else { return }
            self.playVideo(player: avplayer)
        }
    }
    
    func playVideo(player: AVPlayer) {
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) {
            playerController.player?.play()
        }
    }
    
    @objc
    func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    func setupViews() {
        
        view.backgroundColor = UIColor.black
        let safearea = view.safeAreaLayoutGuide
        
        view.addSubview(topView)
        topView.g_pin(on: .left)
        topView.g_pin(on: .right)
        topView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        topView.didTapLeft = { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }
        
        topView.title = nil
        topView.mode = .cameraSelected
        
        view.addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: safearea.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: safearea.trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: safearea.bottomAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: topView.bottomAnchor).isActive = true
        
        view.addSubview(buttonPreview)
        buttonPreview.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
        buttonPreview.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
        buttonPreview.addTarget(self, action: #selector(didTapVideoPlayer), for: .touchUpInside)
    }
}

private extension VideoPreviewController {
    func makeTopView() -> TopView {
        let view = TopView()
        return view
    }
    
    func makePreviewButton() -> UIButton {
        let btn = UIButton()
        btn.setImage(GalleryBundle.image("videoplay"), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }
    
    func makeImageView() -> UIImageView {
        let imgView = UIImageView()
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        return imgView
    }
}

extension VideoPreviewController {
    
    static func show(from: UIViewController, url: URL?, asset: PHAsset?) {
        
        func show(img: UIImage, mode: VideoPreviewController.Mode) {
            let controller = VideoPreviewController()
            controller.previewImage = img
            controller.mode = mode
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .overCurrentContext
            from.present(controller, animated: true, completion: nil)
        }
        
        if let asset = asset {
            asset.getUIImage { img in
                guard let image = img else { return }
                show(img: image, mode: .asset(asset: asset))
            }
        } else if let url = url {
            url.getimage { img in
                guard let image = img else { return }
                show(img: image, mode: .url(url: url))
            }
        }
    }
}

extension FileManager {

     open func secureCopyItem(at srcURL: URL, to dstURL: URL) -> URL? {
         do {
             if FileManager.default.fileExists(atPath: dstURL.path) {
                 try FileManager.default.removeItem(at: dstURL)
             }
             try FileManager.default.copyItem(at: srcURL, to: dstURL)
         } catch (let error) {
             print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
             return nil
         }
         return dstURL
     }

 }
