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
 
    let heartTransitionFilter = AdoreTransition()

    let heartOverlayFilter = TextureOverlayWithTranslationFilter()
    let dotOverlayFilter = TextureOverlayWithTranslationFilter()
    let transformFilter = TransformFilterWithMirror()
    let prevTransformFilter = TransformFilterWithMirror()

    override init(allImageUrls: [URL]) {
        super.init(allImageUrls: allImageUrls)

        outputSize = CGSize(width: 1080, height: 1080)
        setFilterWithImage(index: 0)
        self.duration = Double(Double(allImageUrls.count) * 5.0)
    }
    
    func setFilterWithImage(index:Int) -> Void {
        
        
        let mtiImage = MTIImage(contentsOf: allImageUrls[index], size: outputSize, options: [.SRGB:false], alphaType: .nonPremultiplied)

        heartTransitionFilter.inputImage = mtiImage

        var destIndex = index + 1
        if destIndex >= allImageUrls.count {
            destIndex = 0
        }
        
        let destMtiImage = MTIImage(contentsOf: allImageUrls[destIndex], size: outputSize, options: [.SRGB:false], alphaType: .nonPremultiplied)
        heartTransitionFilter.destImage = destMtiImage

        
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
        
        let singleProgress:Float = 1.0 / Float(allImageUrls.count)
        var start:Float = 0.0, end:Float = 0.0
        
        for i in 0..<allImageUrls.count {
            start = singleProgress * Float(i)
            end = start + singleProgress
            if end >= progress {
                print("image index \(i)")
                break
            }
        }
        
        let currentProgress = smoothStep(edge0: start, edge1: end, x: progress)
        
        heartOverlayFilter.progress = 1.0 - currentProgress
        dotOverlayFilter.progress = (currentProgress * 2.0 - floor(currentProgress * 2.0))
        heartTransitionFilter.progress = sin(0.5 * Float.pi * currentProgress)

        
        transformFilter.resetTransformation()
        let rotateTime = 1.0 - currentProgress
        transformFilter.setScaleUnit(scaleX: 1.0 - 0.25 * rotateTime, scaleY: 1.0 - 0.25 * rotateTime)
        transformFilter.setRotateInAngle(angleInDegree: 5 * rotateTime)

        
        prevTransformFilter.resetTransformation()
        let prevRotateTime = currentProgress
        prevTransformFilter.setScaleUnit(scaleX: 1.0 + 0.25 * prevRotateTime, scaleY: 1.0 + 0.25 * prevRotateTime)
        prevTransformFilter.setRotateInAngle(angleInDegree: -5 * prevRotateTime)
        
        
       // print("adore progress \(progress) currentProgress \(currentProgress) progress \(progress)")
       
       
        let image = FilterGraph.makeImage(builder: { output in
            heartTransitionFilter => transformFilter => heartOverlayFilter => dotOverlayFilter =>  output
        })
        
        
        if currentProgress == 1.0  {
            currentImageIndex += 1
            
            if currentImageIndex >= allImageUrls.count {
                currentImageIndex = 0
            }
            setFilterWithImage(index: currentImageIndex)
        }
        
        return image
               
    }
    
    func smoothStep(edge0:Float,edge1:Float,x:Float) -> Float {
        if x < edge0 {
            return edge0
        }
        if x > edge1 {
            return edge1
        }
        if edge1 <= edge0 {
            return x
        }
        return (x - edge0)/(edge1 - edge0)
    }
    
    private func setLoveRotation() {
        heartTransitionFilter.changeRotation(value: 0.4 /*random.nextFloat()*/);
        heartTransitionFilter.changeRotation(val: 3, pos: (row: 2, col: 1));
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
