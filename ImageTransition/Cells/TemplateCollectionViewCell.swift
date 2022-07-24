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
    var imageUrls = [URL]()
    var localThread:DispatchQueue?
    var workItem:DispatchWorkItem?
    
    var slideShowTemplate:GradualBoxTemplate?{
        didSet{
            slideShowTemplate?.delegate = self
        }
    }
    override class func awakeFromNib() {
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageUrls = [URL]()
        slideShowTemplate?.stopCreatingVideo()
        slideShowTemplate?.delegate = nil
        slideShowTemplate = nil
        imageView.image = nil
        workItem?.cancel()
        workItem = nil
        
    }
    
    func showSelectedTemplate() -> Void {
        
        workItem?.cancel()
        
        workItem = DispatchWorkItem(block: {
            //                self.slideShowTemplate?.createVideo(allImageUrls: self.imageUrls, completion:{ result in
            //                    switch result {
            //                    case .success(let url):
            //                        if self.workItem?.isCancelled == false {
            //                            self.showSelectedTemplate()
            //                        }
            //                        break
            //
            //                    case .failure(_): break
            //
            //                    case .none:
            //                        break
            //                    }
            //                }, forExport: false)
            
            self.slideShowTemplate?.start(completion: { result in
                switch result {
                case .success(let url):
                    if self.workItem?.isCancelled == false {
                        self.showSelectedTemplate()
                    }
                    break
                    
                case .failure(_): break
                    
                case .none:
                    break
                }
            })
            
            
        })
        
        DispatchQueue.global().async {
            self.workItem?.perform()
        }
        
        //            localThread?.async {
        //                self.workItem.perform()
        //            }
        
        self.workItem?.notify(queue: .main) {
            
        }
        
        
    }
    

    
}


extension TemplateCollectionViewCell:SlideShowTemplateDelegate{
    func showImage(image: MTIImage) {
        if workItem == nil || workItem!.isCancelled {
            return
        }
        DispatchQueue.main.async {
            autoreleasepool {
                //self.imageView.image = nil
                self.imageView.image = image
            }
        }
    }
}
