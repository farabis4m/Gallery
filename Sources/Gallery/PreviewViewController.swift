//
//  PreviewViewController.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 4/25/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Photos

class PreviewViewController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    weak var delegate: GalleryControllerDelegate?
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var constraintBottom: NSLayoutConstraint!
    
    private lazy var cropOverlay = makeCropView()

    enum Mode {
        
        case image(image: UIImage)
        case video(video: URL)
        case libraryImage(asset: PHAsset)
        case lbraryVideo(asset: PHAsset)
        
        var shouldShowPreviewButton: Bool {
            switch self {
            case .video: return true
            case .image: return false
            case .libraryImage: return false
            case .lbraryVideo: return true
            }
        }
        
        var shoulShowVideoImageView: Bool {
            return shouldShowPreviewButton
        }
        
        var shouldShowScrollView: Bool {
            return !shoulShowVideoImageView
        }
        
        var shouldShowCropView: Bool {
            return !shoulShowVideoImageView
        }
        
        var galleryMode: GalleryMode {
            switch self {
            case .image, .video: return .cameraSelected
            case .lbraryVideo, .libraryImage: return .photoLibrarySelected
            }
        }
        
        var bottomConstant: CGFloat {
            switch self {
                case .image, .video: return 145.0
                case .lbraryVideo, .libraryImage: return 44.0
            }
        }
    }
    
    private var mode: Mode?
    
    var cart = Cart()

    @IBOutlet weak var videoImageView: UIImageView!
    private lazy var scrollView = makeScrollView()
    var imageView = UIImageView()
    @IBOutlet weak var buttonPreview: UIButton!
    
    private lazy var topView = makeTopView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttonPreview.setImage(GalleryBundle.image("videoplay"), for: .normal)
        
        
        
        containerView.addSubview(scrollView)
        scrollView.frame = containerView.bounds
        
        scrollView.delegate = self
        
        scrollView.addSubview(imageView)
        
        setupViews()
        setupActions()
        
        view.backgroundColor = .clear
        
        let crop = GalleryConfig.shared.cropMode
        containerView.addSubview(cropOverlay)
        cropOverlay.g_pin(on: .centerX)
        cropOverlay.g_pin(on: .centerY)
        
        cropOverlay.isMovable = true
        
        switch crop {
        case .square:
            cropOverlay.g_pin(height: 200)
            cropOverlay.g_pin(width: 200)
        case .rectangle:
            let width = containerView.bounds.width - 40
            let ratio: CGFloat = 200 / 375
            cropOverlay.g_pin(height: width * ratio)
            cropOverlay.g_pin(width: width)
        }
        
        
        guard let mode = mode else { return }
        topView.mode = mode.galleryMode
        buttonPreview.isHidden = !mode.shouldShowPreviewButton
        scrollView.isHidden = !mode.shouldShowScrollView
        videoImageView.isHidden = !mode.shoulShowVideoImageView
        switch mode {
        case .image(let image):
            assignImage(with: image)
        case .video(let url):
            url.getimage { (image) in
                self.videoImageView.image = image
            }
        case .libraryImage(let asset):
            asset.getUIImage { [weak self] (image) in
                guard let img = image else { return }
                self?.assignImage(with: img)
            }
        case .lbraryVideo(let asset):
            asset.getUIImage { [weak self] (image) in
                self?.videoImageView.image = image
            }
        }
    }
    
    
    @IBAction func buttonPreviewTapped(_ sender: Any) {
        guard let mode = mode else { return }
        var player: AVPlayer?
        switch mode {
        case .lbraryVideo(let asset):
            asset.getURL { (url) in
                guard let url = url else { return }
                player = AVPlayer(url: url)
                guard let avplayer = player else { return }
                self.playVideo(player: avplayer)
            }
        case .video(let url):
            player = AVPlayer(url: url)
            guard let avplayer = player else { return }
            self.playVideo(player: avplayer)
        default: break
        }
        
    }
    
    func playVideo(player: AVPlayer) {
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true, completion: nil)
    }
    
    func setupViews() {
        view.addSubview(topView)
        topView.g_pin(on: .left)
        topView.g_pin(on: .right)
        topView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    }
    
    func setupActions() {
        topView.didTapLeft = { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }
        
        topView.didTapRight = { [unowned self] in
            self.crop()
        }
    }
    
    func crop() {
        guard let image = imageView.image else {
            return
        }
        let cropRect = makeProportionalCropRect()
        let resizedCropRect = CGRect(x: (image.size.width) * cropRect.origin.x,
                                     y: (image.size.height) * cropRect.origin.y,
                                     width: (image.size.width * cropRect.width),
                                     height: (image.size.height * cropRect.height))
        
        
        cart.image = image.crop(rect: resizedCropRect)
        dismiss(animated: true) {
            EventHub.shared.finishedWithImage?()
        }
    }

}

extension PreviewViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imageViewSize = imageView.frame.size
        let scrollViewSize = scrollView.bounds.size
        
        let verticalPadding = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalPadding = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        
        if verticalPadding >= 0 {
            // Center the image on screen
            scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
        } else {
            // Limit the image panning to the screen bounds
            scrollView.contentSize = imageViewSize
        }
    }
    
    private func makeProportionalCropRect() -> CGRect {
        var cropRect = CGRect(x: cropOverlay.frame.origin.x + cropOverlay.outterGap,
                              y: cropOverlay.frame.origin.y + cropOverlay.outterGap,
                              width: cropOverlay.frame.size.width - 2 * cropOverlay.outterGap,
                              height: cropOverlay.frame.size.height - 2 * cropOverlay.outterGap)
        cropRect.origin.x += scrollView.contentOffset.x - imageView.frame.origin.x
        cropRect.origin.y += scrollView.contentOffset.y - imageView.frame.origin.y
        
        let normalizedX = max(0, cropRect.origin.x / imageView.frame.width)
        let normalizedY = max(0, cropRect.origin.y / imageView.frame.height)
        
        let extraWidth = min(0, cropRect.origin.x)
        let extraHeight = min(0, cropRect.origin.y)
        
        let normalizedWidth = min(1, (cropRect.width + extraWidth) / imageView.frame.width)
        let normalizedHeight = min(1, (cropRect.height + extraHeight) / imageView.frame.height)
        
        return CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
    }
    
}

private extension PreviewViewController {
    func makeTopView() -> TopView {
        let topView = TopView()
        return topView
    }
    
    func makeCropView() -> CropOverlay {
        let view = CropOverlay()
        view.backgroundColor = .clear
        return view
    }
    
    func makeScrollView() -> UIScrollView {
        let scrollview = UIScrollView()
        scrollview.backgroundColor = .black
        return scrollview
    }
}

extension PreviewViewController {
    private func setZoomScale() {
        let imageViewSize = imageView.bounds.size
        let scrollViewSize = scrollView.bounds.size
        let widthScale = scrollViewSize.width / imageViewSize.width
        let heightScale = scrollViewSize.height / imageViewSize.height
        
        scrollView.minimumZoomScale = min(widthScale, heightScale)
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
    }
    
    private func assignImage(with image: UIImage){
        imageView.image = image
        imageView.backgroundColor = .white
        imageView.sizeToFit()
        setZoomScale()
        scrollViewDidZoom(scrollView)
    }
}

extension PreviewViewController {
    static func show(from: UIViewController, cart: Cart, mode: Mode, delegate: GalleryControllerDelegate) {
        let controller = PreviewViewController(nibName: "PreviewViewController", bundle: Foundation.Bundle(for: GalleryBundle.self))
        controller.modalTransitionStyle = .crossDissolve
        controller.cart = cart
        controller.mode = mode
        controller.delegate = delegate
        controller.modalPresentationStyle = .overCurrentContext
        from.present(controller, animated: true, completion: nil)
    }
}


extension UIImage {
    func crop(rect: CGRect) -> UIImage {
        
        var rectTransform: CGAffineTransform
        switch imageOrientation {
        case .left:
            rectTransform = CGAffineTransform(rotationAngle: radians(90)).translatedBy(x: 0, y: -size.height)
        case .right:
            rectTransform = CGAffineTransform(rotationAngle: radians(-90)).translatedBy(x: -size.width, y: 0)
        case .down:
            rectTransform = CGAffineTransform(rotationAngle: radians(-180)).translatedBy(x: -size.width, y: -size.height)
        default:
            rectTransform = CGAffineTransform.identity
        }
        
        rectTransform = rectTransform.scaledBy(x: scale, y: scale)
        
        if let cropped = cgImage?.cropping(to: rect.applying(rectTransform)) {
            return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation).fixOrientation()
        }
        
        return self
        
        
}
    
    func fixOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
    
}
internal func radians(_ degrees: CGFloat) -> CGFloat {
    return degrees / 180 * .pi
}
