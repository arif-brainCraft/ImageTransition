//
//  TemplateCollectionViewCell.swift
//  ImageTransition
//
//  Created by BCL Device7 on 19/7/22.
//

import UIKit
import MetalPetal

class TemplateCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView:MTIImageView!
    @IBOutlet var nameLabel:UILabel!
    
    var displayLink:CADisplayLink?
    var lastFrameTime:Float = 0

    var slideShowTemplate:SlideShowTemplate?{
        didSet{
            slideShowTemplate?.delegate = self
        }
    }
    override class func awakeFromNib() {
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        slideShowTemplate?.stopCreatingVideo()
        slideShowTemplate?.delegate = nil
        slideShowTemplate = nil
        imageView.image = nil
        lastFrameTime = 0
    }
    
    func addDisplayLink() -> Void {
        NotificationCenter.default.addObserver(self, selector: #selector(displayLinkHandler(notification:)), name: Notification.Name(rawValue: "DisplayLinkHandler"), object: nil)
    }
    
    func removeDisplayLink() -> Void {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "DisplayLinkHandler"), object: nil)
    }
    
    
    @objc func displayLinkHandler(notification:Notification){
        guard let actualFramesPerSecond = notification.userInfo?["actualFramesPerSecond"] as? Double else {
            return
        }
        
        slideShowTemplate?.increaseDisplayCount()
        let progress = slideShowTemplate?.getProgress() ?? 0.0
        if let frame = slideShowTemplate?.getFrame(progress:progress ){
            self.showImage(image: frame)
        }
        if progress >= 1.0 {
            slideShowTemplate?.reset()
        }
        
        lastFrameTime += Float(1.0 / actualFramesPerSecond);
    }
}


extension TemplateCollectionViewCell:SlideShowTemplateDelegate{
    func showImage(image: MTIImage) {

        DispatchQueue.main.async {
            autoreleasepool {
                self.imageView.image = image
                self.imageView.contentMode = .scaleAspectFit
            }
        }
    }
}
