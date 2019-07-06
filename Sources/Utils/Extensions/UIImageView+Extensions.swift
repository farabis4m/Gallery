import UIKit
import Photos

extension UIImageView {

  func g_loadImage(_ asset: PHAsset) {
    guard frame.size != CGSize.zero else {
      image = GalleryBundle.image("gallery_placeholder")
      return
    }

    if tag == 0 {
      image = GalleryBundle.image("gallery_placeholder")
    } else {
      PHImageManager.default().cancelImageRequest(PHImageRequestID(tag))
    }

    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = true

    let id = PHImageManager.default().requestImage(
      for: asset,
      targetSize: frame.size,
      contentMode: .aspectFill,
      options: options) { [weak self] image, _ in
      self?.image = image
    }
    
    tag = Int(id)
  }
}

extension URL {
    
    func getimage(completion: @escaping (UIImage?) -> ()) {
        DispatchQueue.global().async {
            let asset = AVAsset(url: self)
            let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            assetImgGenerate.appliesPreferredTrackTransform = true
            let time = CMTimeMake(value: 1, timescale: 2)
            let img = try? assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            guard let image = img else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            DispatchQueue.main.async {
                completion( UIImage(cgImage: image))
            }
        }
    }
}


extension PHAsset {
    
    func getUIImage(completion: @escaping (UIImage?) -> ()) {
        
        let options = PHImageRequestOptions()
        options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        
        options.progressHandler = {  (progress, error, stop, info) in
            print("progress: \(progress)")
        }
        
        let sz = CGSize(width: CGFloat(pixelHeight), height: CGFloat(pixelHeight))
        
        PHImageManager.default().requestImage(for: self, targetSize: sz, contentMode: PHImageContentMode.aspectFill, options: options, resultHandler: {
            (image, info) in
            print("dict: \(String(describing: info))")
            print("image size: \(String(describing: image?.size))")
            
            DispatchQueue.main.async {
                completion(image)
            }
        })
    }
    
    func getURL(completion: @escaping (URL?) -> ()) {
        PHCachingImageManager().requestAVAsset(forVideo: self, options: nil) { (avasset, _, _) in
            guard let asst = avasset as? AVURLAsset else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            DispatchQueue.main.async {
                completion(asst.url)
            }
        }
    }
}
