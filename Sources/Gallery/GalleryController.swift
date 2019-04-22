import UIKit
import AVFoundation

public protocol GalleryControllerDelegate: class {

  func galleryController(_ controller: GalleryController, didSelectImages images: [Image])
  func galleryController(_ controller: GalleryController, didSelectVideo video: Video)
  func galleryController(_ controller: GalleryController, requestLightbox images: [Image])
  func galleryControllerDidCancel(_ controller: GalleryController)
}

open class GalleryController: UIViewController, PermissionControllerDelegate {

  public weak var delegate: GalleryControllerDelegate?
    
    private lazy var imageController : ImagesController = {
        let controller = ImagesController(cart: cart)
        return controller
    }()
    
    private lazy var cameraController: ArdhiCameraController = {
        let controller = ArdhiCameraController(cart: cart)
        return controller
    }()

  public let cart = Cart()

  // MARK: - Init
  public required init() {
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
    
    let containerView = UIView()

  // MARK: - Life cycle

  open override func viewDidLoad() {
    super.viewDidLoad()

//    view.backgroundColor = UIColor.blue
    setup()
    
    let topView = TopView()
    topView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(topView)
    
    topView.g_pin(on: .top)
    topView.g_pin(on: .left)
    topView.g_pin(on: .right)
    topView.g_pin(height: 40)
    
    let bottomView = BottomView()
    bottomView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(bottomView)
    
    bottomView.g_pin(on: .left)
    bottomView.g_pin(on: .right)
    bottomView.g_pin(on: .bottom)
    bottomView.g_pin(height: 40)
    
    bottomView.didTapLeft = { [unowned self] in
        self.addChildController(self.imageController)
    }
    
    bottomView.didTapRight = { [unowned self] in
        self.cameraController.mode = .video
        self.addChildController(self.cameraController)
    }
    
    bottomView.didTapCenter = {
        self.cameraController.mode = .camera
        self.addChildController(self.cameraController)
    }
    
    topView.didTapRight = {
        EventHub.shared.doneWithImages?()
    }
    
    topView.didTapLeft = {
        EventHub.shared.close?()
    }
    
    
//    containerView.backgroundColor = UIColor.green
    
    view.addSubview(containerView)
    containerView.g_pin(on: .left)
    containerView.g_pin(on: .right)
    containerView.g_pin(on: .top, view: topView, on: .bottom)
    containerView.g_pin(on: .bottom, view: bottomView, on: .top)
    
    addChildController(imageController)
  }
    
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
    

  open override var prefersStatusBarHidden : Bool {
    return true
  }

  // MARK: - Child view controller

  func makeImagesController() -> ImagesController {
    let controller = ImagesController(cart: cart)
//    controller.title = "Gallery.Images.Title".g_localize(fallback: "PHOTOS")
    controller.title = "Library"
    return controller
  }

  func makeCameraController() -> CameraController {
    let controller = CameraController(cart: cart)
    controller.title = "Gallery.Camera.Title".g_localize(fallback: "CAMERA")

    return controller
  }

  func makeVideosController() -> VideosController {
    let controller = VideosController(cart: cart)
    controller.title = "Gallery.Videos.Title".g_localize(fallback: "VIDEOS")

    return controller
  }

  func makePagesController() -> PagesController? {
    guard Permission.Photos.status == .authorized else {
      return nil
    }

    let useCamera = Permission.Camera.needsPermission && Permission.Camera.status == .authorized

    let tabsToShow = Config.tabsToShow.compactMap { $0 != .cameraTab ? $0 : (useCamera ? $0 : nil) }

    let controllers: [UIViewController] = tabsToShow.compactMap { tab in
      if tab == .imageTab {
        return makeImagesController()
      } else if tab == .cameraTab {
        return makeCameraController()
      } else if tab == .videoTab {
        return makeVideosController()
      } else {
        return nil
      }
    }

    guard !controllers.isEmpty else {
      return nil
    }

    let controller = PagesController(controllers: controllers)
    controller.selectedIndex = tabsToShow.index(of: Config.initialTab ?? .cameraTab) ?? 0

    return controller
  }

  func makePermissionController() -> PermissionController {
    let controller = PermissionController()
    controller.delegate = self

    return controller
  }

  // MARK: - Setup

  func setup() {
    EventHub.shared.close = { [weak self] in
      if let strongSelf = self {
        strongSelf.delegate?.galleryControllerDidCancel(strongSelf)
      }
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

  // MARK: - PermissionControllerDelegate

  func permissionControllerDidFinish(_ controller: PermissionController) {
    if let pagesController = makePagesController() {
      g_addChildController(pagesController)
      controller.g_removeFromParentController()
    }
  }
}

class BottomView: UIView {
    
    var didTapLeft: (() -> ())?
    var didTapCenter: (() -> ())?
    var didTapRight: (() -> ())?
    
    private lazy var leftButton = makeButton()
    private lazy var centerButton = makeButton()
    private lazy var rightButton = makeButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        
        backgroundColor = .red
        
        [leftButton, centerButton, rightButton].forEach {
            addSubview($0)
            $0.g_pin(on: .centerY)
        }
        
        leftButton.tag = 0
        centerButton.tag = 1
        rightButton.tag = 2
        
        leftButton.g_pin(on: .left, constant: 8)
        centerButton.g_pin(on: .centerX, constant: 8)
        rightButton.g_pin(on: .right, constant: -8)
        
        [leftButton, centerButton, rightButton].forEach {
            $0.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }
    }
    
    @objc
    private func buttonTapped(_ sender: UIButton) {
        switch sender.tag {
        case 0: didTapLeft?()
        case 1: didTapCenter?()
        case 2: didTapRight?()
        default: break
        }
    }
    
    private func makeButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitle("Test", for: .normal)
        return button
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
}

