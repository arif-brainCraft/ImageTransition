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
        slideShowTemplate?.delegate = nil
        slideShowTemplate = nil
        imageView.image = nil
    }
    
    func showSelectedTemplate() -> Void {
        
        DispatchQueue.global().async {
            self.slideShowTemplate?.createVideo(allImageUrls: self.imageUrls, completion:{ result in
                switch result {
                case .success(let url):
                    self.showSelectedTemplate()
                    break
                    
                case .failure(_): break

                case .none:
                    break
                }
            }, forExport: false)
        }
        

    }
    
}

extension TemplateCollectionViewCell:SlideShowTemplateDelegate{
    func showImage(image: MTIImage) {
        DispatchQueue.main.async {
            autoreleasepool {
                self.imageView.image = nil
                self.imageView.image = image
            }
        }
    }
    
    
}
