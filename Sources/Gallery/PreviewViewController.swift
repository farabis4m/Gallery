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
    
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        guard let window = UIApplication.shared.keyWindow else { return }
        let safeAreaTop = window.safeAreaInsets.top; let safeAreaBottom = window.safeAreaInsets.bottom
        containerView.frame = CGRect(x: 0, y: 50 + safeAreaTop, width: view.frame.width, height: view.frame.height - 50 - safeAreaTop - safeAreaBottom)
        scrollView.frame = containerView.bounds
        
    }
    
    var wholeRect = CGRect.zero
    
    var isInitially = true
    
    let aspectHeight: CGFloat = 1.0
    let aspectWidth: CGFloat = 1.0
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var cropOrigin : CGFloat {
        let width = containerView.frame.width
        let height = width * aspectHeight
        let center = containerView.frame.height / 2
        return center - (height / 2)
    }
    
    weak var delegate: GalleryControllerDelegate?
    
    lazy var containerView = UIView()

    enum Mode {
        case image(image: UIImage)
        case libraryImage(asset: PHAsset)
        
        var galleryMode: GalleryMode {
            switch self {
            case .image: return .cameraSelected
            case .libraryImage: return .photoLibrarySelected
            }
        }
    }
    
    private var mode: Mode?
    
    var cart = Cart()

    private lazy var scrollView = makeScrollView()
    var imageView = UIImageView()
    
    private lazy var topView = makeTopView()
    
    var hollowView: HollowView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupImageView()
        setupActions()
        updateMode()
        setupHollowView()
    }
    
    func updateInitially(with image: UIImage) {
        let width = containerView.bounds.width
        let height = width * aspectHeight / aspectWidth
        wholeRect = CGRect(x: 0, y: containerView.bounds.height/2-height/2, width: width, height: height)
        imageView.image = image
        imageView.sizeToFit()
        
        let minZoom = max(width / image.size.width, height / image.size.height)
        scrollView.minimumZoomScale = minZoom
        scrollView.zoomScale = minZoom
        scrollView.maximumZoomScale = minZoom*4
        
        guard scrollView.zoomScale == 1.0 else { return }
        
        scrollView.setZoomScale(minZoom, animated: true)
        let desiredOffset = CGPoint(x: 0, y: -scrollView.contentInset.top)
        scrollView.setContentOffset(desiredOffset, animated: false)
    }
    
    func playVideo(player: AVPlayer) {
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true, completion: nil)
    }
    
    func setupViews() {
        view.backgroundColor = .black
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
            if GalleryConfig.shared.isCroppingEnabled {
                self.crop()
            } else {
                self.cart.image = self.imageView.image
                self.dismiss(animated: true, completion: {
                    EventHub.shared.finishedWithImage?()
                })
            }
        }
    }
    
    func crop() {
        guard let image = imageView.image else { return }
        let scale = 1 / scrollView.zoomScale
        let visibleRect = CGRect(
            x: (scrollView.contentOffset.x + scrollView.contentInset.left) * scale,
            y: (scrollView.contentOffset.y + scrollView.contentInset.top) * scale,
            width: containerView.frame.width * scale,
            height: containerView.frame.width * aspectHeight * scale)
            cart.image = image.crop(rect: visibleRect)
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
        let gapToTheHole = containerView.frame.height/2-wholeRect.height/2
        scrollView.contentInset = UIEdgeInsets(top: gapToTheHole , left: 0, bottom: gapToTheHole , right: 0)
    }
}

private extension PreviewViewController {
    func makeTopView() -> TopView {
        let topView = TopView()
        return topView
    }
    
    func makeScrollView() -> UIScrollView {
        let scrollview = UIScrollView()
        scrollview.backgroundColor = .black
        return scrollview
    }
}

private extension PreviewViewController {
    
    func updateMode() {
        guard let mode = mode else { return }
        topView.mode = mode.galleryMode
        switch mode {
        case .image(let image):
            
            if GalleryConfig.shared.isCroppingEnabled {
                updateInitially(with: image)
            } else {
                imageView.image = image
            }
            
        case .libraryImage(let asset):
            asset.getUIImage { [weak self] (image) in
                guard let img = image else { return }
                if GalleryConfig.shared.isCroppingEnabled {
                    self?.updateInitially(with: img)
                } else {
                    self?.imageView.image = img
                }
            }
        }
    }
    
    

}

private extension PreviewViewController {
    
    func setupImageView() {
        if GalleryConfig.shared.isCroppingEnabled {
            configureScrollView()
            setupViews()
        } else {
            setupViews()
            configureImageViewWithoutScrolling()
        }
    }
    
    func configureScrollView() {
        view.addSubview(containerView)
        
        containerView.backgroundColor = .clear
        
        guard let window = UIApplication.shared.keyWindow else { return }
        let safeAreaTop = window.safeAreaInsets.top; let safeAreaBottom = window.safeAreaInsets.bottom
        containerView.frame = CGRect(x: 0, y: 50 + safeAreaTop, width: view.frame.width, height: view.frame.height - 50 - safeAreaTop - safeAreaBottom)
        
        containerView.addSubview(scrollView)
        scrollView.frame = containerView.bounds
        
        scrollView.decelerationRate = .fast
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        
        scrollView.addSubview(imageView)
    }
    
    func configureImageViewWithoutScrolling() {
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        let layout = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: layout.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: layout.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: layout.bottomAnchor),
            imageView.topAnchor.constraint(equalTo: topView.bottomAnchor)
            ])
    }
    
    func setupHollowView() {
        guard GalleryConfig.shared.isCroppingEnabled else { return }
        hollowView = HollowView(frame: containerView.bounds, transparentRect: CGRect(x: 0, y: cropOrigin, width: containerView.frame.width  , height: containerView.frame.width * aspectHeight ))
        containerView.addSubview(hollowView!)
    }
}

extension PreviewViewController {
    static func show(from: UIViewController, cart: Cart, mode: Mode, delegate: GalleryControllerDelegate) {
        let controller = PreviewViewController()
        controller.cart = cart
        controller.mode = mode
        controller.delegate = delegate
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .overCurrentContext
        from.present(controller, animated: true, completion: nil)
    }
}
