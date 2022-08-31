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
    let heartOverlayFilter = TextureOverlayWithTranslationFilter()
    let dotOverlayFilter = TextureOverlayWithTranslationFilter()
    let shakyZoomFilter = ShakyZoom()
    let prevShakyZoomFilter = ShakyZoom()

    override init(allImageUrls: [URL]) {
        super.init(allImageUrls: allImageUrls)

        outputSize = CGSize(width: 1080, height: 1080)
        setFilterWithImage(index: 0)
        self.duration = Double(Double(allImageUrls.count) * adoreTransitionFilter.duration)
    }
    
    func setFilterWithImage(index:Int) -> Void {
        
        
        let mtiImage = MTIImage(contentsOf: allImageUrls[index], size: outputSize, options: [.SRGB:false], alphaType: .nonPremultiplied)
        
        shakyZoomFilter.inputImage = mtiImage
        adoreTransitionFilter.inputImage = mtiImage
        heartOverlayFilter.inputImage = mtiImage
        dotOverlayFilter.inputImage = mtiImage
        
        if index + 1 < allImageUrls.count {
            let destMtiImage = MTIImage(contentsOf: allImageUrls[index + 1], size: outputSize, options: [.SRGB:false], alphaType: .nonPremultiplied)
            adoreTransitionFilter.destImage = destMtiImage
            shakyZoomFilter.destImage = destMtiImage

        }else{
            adoreTransitionFilter.destImage = mtiImage
            shakyZoomFilter.destImage = mtiImage

        }
        
        
        if heartOverlayFilter.destImage == nil, let url = Bundle.main.url(forResource: "love", withExtension: "png") {
            let mtiStroke = MTIImage(contentsOf: url, size: CGSize(width: outputSize.width - 160, height: outputSize.height - 160), options: [.SRGB:false], alphaType: .nonPremultiplied)
            heartOverlayFilter.destImage = mtiStroke
        }
        
        if dotOverlayFilter.destImage == nil, let url = Bundle.main.url(forResource: "dots", withExtension: "png") {
            let mtiStroke = MTIImage(contentsOf: url, size: CGSize(width: outputSize.width - 160, height: outputSize.height - 160), options: [.SRGB:false], alphaType: .nonPremultiplied)
            dotOverlayFilter.destImage = mtiStroke
        }
        heartOverlayFilter.opacityMul = 0.15
        dotOverlayFilter.opacityMul = 0.3
    }
    
    
    var currentAnim = 0,prevAnim = 0,currentImageIndex = 0
    
    override func getFrame(progress: Float) -> MTIImage? {
        
        
        heartOverlayFilter.progress = 1.0 - progress
        dotOverlayFilter.progress = (progress * 2.0 - floor(progress * 2.0))
        adoreTransitionFilter.progress = sin(0.5 * Float.pi * progress)
        shakyZoomFilter.progress = sin(0.5 * Float.pi * progress)

        if adoreTransitionFilter.progress == 1.0  {
            currentImageIndex += 1
            
            if currentImageIndex >= allImageUrls.count {
                currentImageIndex = 0
            }
            setFilterWithImage(index: currentImageIndex)

        }
        

        
        //adoreTransitionFilter.progress = 1.0 - adoreTransitionFilter.progress

        print("adore progress \(adoreTransitionFilter.progress) progress \(progress)")

        let image = FilterGraph.makeImage(builder: { output in
            heartOverlayFilter=>dotOverlayFilter=>adoreTransitionFilter=>output
        })
        
        shakyZoomFilter.inputImage = image
       
        
        return shakyZoomFilter.outputImage
    }
    
    private func setLoveRotation() {
        adoreTransitionFilter.changeRotation(value: 0.4 /*random.nextFloat()*/);
        adoreTransitionFilter.changeRotation(val: 3, pos: (row: 2, col: 1));
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
