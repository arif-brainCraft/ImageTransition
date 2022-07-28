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
        
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkHandler))
        displayLink?.add(to: .current, forMode: .common)
        if #available(iOS 15.0, *) {
            displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 40, __preferred: 30)
        } else {
            displayLink?.preferredFramesPerSecond = 40
        }
        
       // NotificationCenter.default.addObserver(self, selector: #selector(displayLinkHandler(notification:)), name: Notification.Name(rawValue: "DisplayLinkHandler"), object: nil)
    }
    
    func removeDisplayLink() -> Void {
        self.displayLink?.invalidate()
        self.displayLink = nil
        //NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "DisplayLinkHandler"), object: nil)
    }
    
    
    @objc func displayLinkHandler(){
//        guard let actualFramesPerSecond = notification.userInfo?["actualFramesPerSecond"] as? Double else {
//            return
//        }
        guard displayLink != nil else{return}
        
        let actualFramesPerSecond = 1 / (displayLink!.targetTimestamp - displayLink!.timestamp)

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
