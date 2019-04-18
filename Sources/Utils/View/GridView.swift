import UIKit
import Photos

class GridView: UIView {

    var isButtonRightHidden = false {
        didSet {
            topView.buttonRight.isHidden = isButtonRightHidden
        }
    }
    
    var didTapButtonLeft: ((UIButton) -> Void )?
    var didTapButtonRight: ((UIButton) -> Void )?
    
  // MARK: - Initialization

  lazy var topView: TopView = self.makeTopView()
  lazy var bottomView: UIView = self.makeBottomView()
  lazy var bottomBlurView: UIVisualEffectView = self.makeBottomBlurView()
//  lazy var arrowButton: ArrowButton = self.makeArrowButton()
  lazy var collectionView: UICollectionView = self.makeCollectionView()
  lazy var closeButton: UIButton = self.makeCloseButton()
  lazy var doneButton: UIButton = self.makeDoneButton()
  lazy var emptyView: UIView = self.makeEmptyView()
  lazy var loadingIndicator: UIActivityIndicatorView = self.makeLoadingIndicator()

  // MARK: - Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)

    setup()
    loadingIndicator.startAnimating()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup

  private func setup() {
    [collectionView, bottomView, topView, emptyView, loadingIndicator].forEach {
      addSubview($0)
    }

//    [closeButton, arrowButton].forEach {
//      topView.addSubview($0)
//    }

    [bottomBlurView, doneButton].forEach {
        bottomView.addSubview($0)
    }

    Constraint.on(
      topView.leftAnchor.constraint(equalTo: topView.superview!.leftAnchor),
      topView.rightAnchor.constraint(equalTo: topView.superview!.rightAnchor),
      topView.heightAnchor.constraint(equalToConstant: 60),

      loadingIndicator.centerXAnchor.constraint(equalTo: loadingIndicator.superview!.centerXAnchor),
      loadingIndicator.centerYAnchor.constraint(equalTo: loadingIndicator.superview!.centerYAnchor)
    )

    if #available(iOS 11, *) {
      Constraint.on(
        topView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
      )
    } else {
      Constraint.on(
        topView.topAnchor.constraint(equalTo: topView.superview!.topAnchor)
      )
    }

    bottomView.g_pinDownward()
    bottomView.g_pin(height: 80)

    emptyView.g_pinEdges(view: collectionView)
    
    collectionView.g_pinDownward()
    collectionView.g_pin(on: .top, view: topView, on: .bottom, constant: 1)

    bottomBlurView.g_pinEdges()

    closeButton.g_pin(on: .top)
    closeButton.g_pin(on: .left)
    closeButton.g_pin(size: CGSize(width: 40, height: 40))

//    arrowButton.g_pinCenter()
//    arrowButton.g_pin(height: 40)

    doneButton.g_pin(on: .centerY)
    doneButton.g_pin(on: .right, constant: -38)
    
    isButtonRightHidden = true
    
    topView.buttonLeft.addTarget(self, action: #selector(buttonLeftTapped(_:)), for: .touchUpInside)
    topView.buttonRight.addTarget(self, action: #selector(buttonRightTapped(_:)), for: .touchUpInside)
  }
    
    @objc
    func buttonRightTapped(_ sender: UIButton) {
        didTapButtonRight?(sender)
    }
    
    @objc
    func buttonLeftTapped(_ sender: UIButton) {
        didTapButtonLeft?(sender)
    }

  // MARK: - Controls

  private func makeTopView() -> TopView {
    let view = TopView()
    view.backgroundColor = UIColor.red

    return view
  }

  private func makeBottomView() -> UIView {
    let view = UIView()

    return view
  }

  private func makeBottomBlurView() -> UIVisualEffectView {
    let view = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    return view
  }

  private func makeArrowButton() -> ArrowButton {
    let button = ArrowButton()
    button.layoutSubviews()

    return button
  }

  private func makeGridView() -> GridView {
    let view = GridView()

    return view
  }

  private func makeCloseButton() -> UIButton {
    let button = UIButton(type: .custom)
    button.setImage(GalleryBundle.image("gallery_close")?.withRenderingMode(.alwaysTemplate), for: UIControl.State())
    button.tintColor = Config.Grid.CloseButton.tintColor

    return button
  }

  private func makeDoneButton() -> UIButton {
    let button = UIButton(type: .system)
    button.setTitleColor(UIColor.white, for: UIControl.State())
    button.setTitleColor(UIColor.lightGray, for: .disabled)
    button.titleLabel?.font = Config.Font.Text.regular.withSize(16)
    button.setTitle("Gallery.Done".g_localize(fallback: "Done"), for: UIControl.State())
    
    return button
  }

  private func makeCollectionView() -> UICollectionView {
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 2
    layout.minimumLineSpacing = 2

    let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
    view.backgroundColor = UIColor.black

    return view
  }

  private func makeEmptyView() -> EmptyView {
    let view = EmptyView()
    view.isHidden = true

    return view
  }

  private func makeLoadingIndicator() -> UIActivityIndicatorView {
    let view = UIActivityIndicatorView(style: .whiteLarge)
    view.color = .gray
    view.hidesWhenStopped = true

    return view
  }
}

class TopView: UIView {
    
    var padding: CGFloat = 8
    
    var leftTitle: String? {
        didSet {
            buttonLeft.setTitle(leftTitle, for: .normal)
        }
    }
    
    var title: String? {
        didSet {
            labelTitle.text = title
        }
    }
    
    var rightTitle: String? {
        didSet {
            buttonRight.setTitle(rightTitle, for: .normal)
        }
    }
    
    lazy var buttonLeft = makeButtonLeft()
    lazy var labelTitle = makeLabelTitle()
    lazy var buttonRight = makeButtonRight()
    
    private func makeButtonLeft() -> UIButton {
        let button = UIButton()
        button.setTitleColor(UIColor.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("left", for: .normal)
        return button
    }
    
    private func makeLabelTitle() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.white
        label.text = "title"
        return label
    }
    
    private func makeButtonRight() -> UIButton {
        let button = UIButton()
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitle("right", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        addSubview(buttonLeft)
        
        NSLayoutConstraint.activate([
            buttonLeft.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            buttonLeft.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        addSubview(labelTitle)
        NSLayoutConstraint.activate([
            labelTitle.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelTitle.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        
        addSubview(buttonRight)
        NSLayoutConstraint.activate([
            buttonRight.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            buttonRight.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
