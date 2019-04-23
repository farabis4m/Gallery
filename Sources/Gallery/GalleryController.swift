import UIKit
import AVKit
import AVFoundation

public protocol GalleryControllerDelegate: class {
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image])
    func galleryController(_ controller: GalleryController, didSelectVideo video: Video)
    func galleryController(_ controller: GalleryController, requestLightbox images: [Image])
    func galleryControllerDidCancel(_ controller: GalleryController)
}

open class GalleryController: UIViewController {
    
    // MARK: - Init
    public required init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override var prefersStatusBarHidden : Bool {
        return true
    }
    
    public let cart = Cart()
    
    var galleryMode: GalleryMode = .cameraUnselected {
        didSet {
            updateTopAndPreviewView()
        }
    }
    
    enum GalleryType{
        case photoLibrary
        case camera
    }
    
    var galleryType: GalleryType = .camera
    
    let containerView = UIView()
    let topView = TopView()
    let bottomView = BottomView()
    
    private lazy var previewImageView: VideoImagePreviewView = {
        let view = VideoImagePreviewView(frame: .zero)
        return view
    }()
    
    public weak var delegate: GalleryControllerDelegate?
    
    private lazy var imageController : ImagesController = {
        let controller = ImagesController(cart: cart)
        return controller
    }()
    
    private lazy var cameraController: ArdhiCameraController = {
        let controller = ArdhiCameraController(cart: cart)
        return controller
    }()
    
    private lazy var videoController: ArdhiCameraController = {
        let controller = ArdhiCameraController(cart: cart)
        controller.mediaType = .video
        return controller
    }()
    
    // MARK: - Life cycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        setupViews()
        setupActions()
        updateTopAndPreviewView()
        self.cameraController.mediaType = .camera
        addChildController(cameraController)
        
        previewImageView.didTapVideo = { [weak self] url in
            let player = AVPlayer(url: url)
            let vc = AVPlayerViewController()
            vc.player = player
            
            self?.present(vc, animated: true) {
                vc.player?.play()
            }
        }
    }
}

extension GalleryController {
    // MARK: - Setup
    func setup() {
        EventHub.shared.close = { [weak self] in
            if let strongSelf = self {
                strongSelf.delegate?.galleryControllerDidCancel(strongSelf)
            }
        }
        
        EventHub.shared.capturedImage = { [weak self] in
            guard let welf = self else { return }
            guard let image = welf.cart.image else { return }
            welf.previewImageView.media = VideoImagePreviewView.MediaType.image(image: image)
            welf.galleryMode = .cameraSelected
        }
        
        EventHub.shared.capturedVideo = { [weak self] in
            guard let welf = self, let url = welf.cart.url else { return }
            welf.previewImageView.media = VideoImagePreviewView.MediaType.video(url: url)
            welf.galleryMode = .cameraSelected
        }
        
        EventHub.shared.doneWithImages = { [weak self] in
            if let strongSelf = self {
                strongSelf.delegate?.galleryController(strongSelf, didSelectImages: strongSelf.cart.images)
            }
        }
        
        EventHub.shared.doneWithVideos = { [weak self] in
            if let strongSelf = self, let video = strongSelf.cart.video {
                strongSelf.delegate?.galleryController(strongSelf, didSelectVideo: video)
            }
        }
        
        EventHub.shared.stackViewTouched = { [weak self] in
            if let strongSelf = self {
                strongSelf.delegate?.galleryController(strongSelf, requestLightbox: strongSelf.cart.images)
            }
        }
    }
}


private extension GalleryController {
    
    private func addChildController<T: UIViewController>(_ controller: T) where T : PageAware {
        if let ctrl = children.first {
            removeFromParentController(ctrl)
        }
        addChild(controller)
        containerView.addSubview(controller.view)
        controller.didMove(toParent: self)
        controller.view.g_pinEdges()
        controller.pageDidShow()
    }
    
    func removeFromParentController(_ controller: UIViewController) {
        controller.willMove(toParent: nil)
        controller.view.removeFromSuperview()
        controller.removeFromParent()
    }
}

private extension GalleryController {
    
    func setupViews() {
        view.addSubview(topView)
        
        topView.g_pin(on: .top)
        topView.g_pin(on: .left)
        topView.g_pin(on: .right)
        topView.g_pin(height: 40)
        
        view.addSubview(bottomView)
        bottomView.g_pin(on: .left)
        bottomView.g_pin(on: .right)
        bottomView.g_pin(on: .bottom)
        bottomView.g_pin(height: 40)
        
        view.addSubview(containerView)
        containerView.g_pin(on: .left)
        containerView.g_pin(on: .right)
        containerView.g_pin(on: .top, view: topView, on: .bottom)
        containerView.g_pin(on: .bottom, view: bottomView, on: .top)
        
        
        view.addSubview(previewImageView)
        previewImageView.g_pin(on: .top, view: topView, on: .bottom)
        previewImageView.g_pin(on: .left)
        previewImageView.g_pin(on: .right)
        previewImageView.g_pin(on: .bottom, view: bottomView, on: .top)
    }
    
    func updateTopAndPreviewView() {
        topView.mode = galleryMode
        previewImageView.isHidden = !galleryMode.shouldShowPreviewScreen
    }
    
    func setupActions() {
        bottomView.didTapLeft = { [unowned self] in
            self.addChildController(self.imageController)
        }
        
        bottomView.didTapCenter = {
            self.addChildController(self.cameraController)
        }
        
        bottomView.didTapRight = { [unowned self] in
            self.addChildController(self.videoController)
        }
        
        topView.didTapRight = {
            EventHub.shared.doneWithImages?()
        }
        
        topView.didTapLeft = { [unowned self] in
            switch  self.galleryMode {
            case .cameraSelected:
                self.galleryMode = .cameraUnselected
                self.cameraController.viewBottom.mode = .enabled
            case .cameraUnselected, .photoLibrarySelected, .photoLibraryUnselected: EventHub.shared.close?()
            }
        }
    }
}
