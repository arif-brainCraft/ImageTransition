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
    
    var lastFrameTime:Float = 0

    var slideShowTemplate:SlideShowTemplate?{
        didSet{
            self.slideShowTemplate?.delegate = self
        }
    }
    override class func awakeFromNib() {
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.slideShowTemplate?.stopCreatingVideo()
        self.slideShowTemplate?.delegate = nil
        self.slideShowTemplate = nil
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


        self.slideShowTemplate?.increaseDisplayCount()
        let progress = self.slideShowTemplate?.getProgress() ?? 0.0
        if let frame = self.slideShowTemplate?.getFrame(progress:progress ){
            self.showImage(image: frame)
        }
        if progress >= 1.0 {
            self.slideShowTemplate?.reset()
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
