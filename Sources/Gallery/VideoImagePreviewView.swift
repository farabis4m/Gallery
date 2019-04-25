//
//  VideoImagePreviewView.swift
//  Gallery-iOS
//
//  Created by Muhammed Azharudheen on 4/23/19.
//  Copyright © 2019 Hyper Interaktiv AS. All rights reserved.
//

import UIKit

class VideoImagePreviewView: UIView {
    
    private lazy var buttonVideoPreview = makeVideoPreviewButton()
    private lazy var scrollView = makeScrollView()
    private lazy var backGroundView = makeBackgroundView()
    
    var didTapVideo: ((URL) -> ())?

    enum MediaType {
        case image(image: UIImage)
        case video(url: URL)
    }
    
    var media: MediaType? = nil {
        didSet {
            updatePreview()
        }
    }
    
    lazy var imageView = makeImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        
        addSubview(scrollView)
        scrollView.g_pin(on: .left)
        scrollView.g_pin(on: .right)
        scrollView.g_pin(on: .top)
        scrollView.g_pin(on: .bottom, constant: -101)
        
        scrollView.addSubview(imageView)
        imageView.g_pinEdges()
        
        addSubview(buttonVideoPreview)
        buttonVideoPreview.g_pinCenter(view: imageView)
        buttonVideoPreview.addTarget(self, action: #selector(previewVideoTapped), for: .touchUpInside)
    }
    
    @objc
    private func previewVideoTapped() {
        guard let media = media else { return }
        switch media {
        case .video(let url): didTapVideo?(url)
        case .image: break
        }
    }
    
    private func updatePreview() {
        isHidden = media == nil
        guard let media = media else { return }
        switch media {
        case .image(let image):
            assignImage(with: image)
            buttonVideoPreview.isHidden = true
        case .video(let url):
            imageView.layoutIfNeeded()
            imageView.g_loadImage(url)
            buttonVideoPreview.isHidden = false
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func makeVideoPreviewButton() -> UIButton {
        let button = UIButton()
        button.setImage(GalleryBundle.image("videoplay"), for: .normal)
        return button
    }
}

private extension VideoImagePreviewView {
    
    func makeImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.black
        imageView.clipsToBounds = true
        return imageView
    }
    
    func makeScrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .black
        scrollView.delegate = self
        return scrollView
    }
}

private extension VideoImagePreviewView {
    
    private func setZoomScale() {
        let imageViewSize = imageView.bounds.size
        let scrollViewSize = scrollView.bounds.size
        let widthScale = scrollViewSize.width / imageViewSize.width
        let heightScale = scrollViewSize.height / imageViewSize.height
        
        scrollView.minimumZoomScale = min(widthScale, heightScale)
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
    }
    
    private func makeBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }
    
    private func assignImage(with image: UIImage){
        imageView.image = image
        imageView.sizeToFit()
        setZoomScale()
        scrollViewDidZoom(scrollView)
    }
}


extension VideoImagePreviewView: UIScrollViewDelegate {
    
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
}
