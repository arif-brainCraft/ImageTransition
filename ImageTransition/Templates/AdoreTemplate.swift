//
//  AdoreTemplate.swift
//  ImageTransition
//
//  Created by BCL Device7 on 23/8/22.
//

import UIKit
import MetalPetal
import MTTransitions
import simd

class AdoreTemplate: SlideShowTemplate {
 
    let adoreTransitionFilter = AdoreTransition()
    
    
    override init(allImageUrls: [URL]) {
        super.init(allImageUrls: allImageUrls)

        outputSize = CGSize(width: 1080, height: 1080)
        setFilterWithImage(url: allImageUrls.first!)
        self.duration = Double(allImageUrls.count * 3)
    }
    
    func setFilterWithImage(url:URL) -> Void {
        
        
        
    }
    
    
    var currentAnim = 0,prevAnim = 0,currentImageIndex = 0
    
    override func getFrame(progress: Float) -> MTIImage? {
        
        let schedule = super.getSchedule(progress: progress)
        
        if schedule.imageIndex != currentImageIndex  {
            currentImageIndex = schedule.imageIndex
            //print("imageIndex \(imageIndex) progress \(progress)")
            
            if schedule.imageIndex < allImageUrls.count {
                setFilterWithImage(url: allImageUrls[schedule.imageIndex])
                prevAnim = currentAnim
                currentAnim = Int.random(in: 0..<2)
                //presentTime = CMTimeAdd(presentTime, CMTime(value: 100, timescale: 1000))
            }
        }
        
        if schedule.imageIndex < allImageUrls.count ,let ciimage = CIImage(contentsOf: allImageUrls[schedule.imageIndex]){
            let image = applyRotationTransform(ciimage:ciimage , progress: progress)
            return MTIImage(ciImage: image)

        }
        return MTIImage(contentsOf: allImageUrls[0], size: outputSize, options: [.SRGB:false], alphaType: .nonPremultiplied)
    }
    
    func applyRotationTransform(ciimage:CIImage,progress:Float) -> CIImage {
        var image = ciimage
        let angle = CGFloat(simd_smoothstep(0, 0.5, progress/2))
        let scale = CGFloat(simd_smoothstep(0.7, 1,1 - progress ) + 0.5)
        print("angle \(angle) scale \(scale)")
       // image = image.transformed(by: CGAffineTransform(rotationAngle: angle))
        image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        let blurOutput = self.applyGaussianBlurEffect(image: ciimage)
        
        let sourceOverCompositing = CIFilter(name: "CISourceOverCompositing")
        sourceOverCompositing?.setValue(blurOutput, forKey: kCIInputBackgroundImageKey)
        sourceOverCompositing?.setValue(image, forKey: kCIInputImageKey)

        
        return sourceOverCompositing?.outputImage ?? ciimage
    }
    
    
    func applyGaussianBlurEffect(image:CIImage) -> CIImage? {
        
        let clampFilter = CIFilter(name: "CIAffineClamp")
        clampFilter?.setDefaults()
        clampFilter?.setValue(image, forKey: kCIInputImageKey)
        
        let gaussianBlurFilter = CIFilter(name:"CIGaussianBlur")
        gaussianBlurFilter?.setValue(clampFilter?.outputImage, forKey: kCIInputImageKey)
        gaussianBlurFilter?.setValue(15, forKey: kCIInputRadiusKey)
        
        return gaussianBlurFilter?.outputImage?.cropped(to: image.extent)
        
    }
}
