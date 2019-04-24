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
        addSubview(imageView)
        imageView.g_pin(on: .left)
        imageView.g_pin(on: .right)
        imageView.g_pin(on: .top)
        imageView.g_pin(on: .bottom, constant: -101)
        
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
            imageView.image = image
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
        imageView.clipsToBounds = true
        return imageView
    }
}
