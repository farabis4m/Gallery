import UIKit

class EventHub {
    
    typealias Action = () -> Void
    typealias VideoAction = (URL?, UIImage?) -> Void
    
    static let shared = EventHub()
    
    // MARK: Initialization
    
    init() {}
    
    var close: Action?
    var doneWithImages: Action?
    var doneWithVideos: Action?
    var videoSizeExceeded: Action?
    var stackViewTouched: Action?
    var capturedImage: Action?
    var capturedVideo: Action?
    var dismissPreview: Action?
    var finishedWithImage: Action?
    var didCancelPermission: Action?
    var videoUrl: VideoAction?
}
