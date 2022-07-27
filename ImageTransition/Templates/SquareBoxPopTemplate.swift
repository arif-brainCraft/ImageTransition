//
//  SlideShowTemplate.swift
//  ImageTransition
//
//  Created by BCL Device7 on 14/6/22.
//

import UIKit
import MetalPetal
import CoreImage
import CoreMedia

class SquareBoxPopTemplate:SlideShowTemplate{
    

    var transitionFilter:BCLTransition?
    
    var currentFilter: BCLTransition?
    var prevFilter:BCLTransition?
    
    var currentBlendImage:CIImage?
    var prevBlendImage:CIImage?

    
    override init(allImageUrls: [URL], forExport: Bool) {
        super.init(allImageUrls: allImageUrls, forExport: forExport)
        outputSize = CGSize(width: 1080, height: 1080)
        setFilterWithImage(url: allImageUrls.first!)

        self.duration = currentFilter!.duration * Double(allImageUrls.count) + 1.0 * Double(allImageUrls.count)

    }
    
    
    func setFilterWithImage(url:URL) -> Void {


        
        prevFilter = currentFilter
        prevBlendImage = currentBlendImage
        
        currentBlendImage = self.blendWihtBlurBackground(image: loadImageFromUrl(url: url), bRatio: (x: 0.6, y: 0.7), fRatio: (x: 0.6, y: 0.4))

        let mtiImage = MTIImage(contentsOf: url, size: outputSize, options: [.SRGB:false], alphaType: .nonPremultiplied)
        
        currentFilter = WhiteMinimalBgFilter()
        currentFilter?.inputImage = mtiImage
        currentFilter?.destImage = mtiImage
        
        if Int.random(in: 0...1) == 0 {
            transitionFilter?.parameters["direction"] = simd_float2(x: 0.0, y: 1.0)
        }else{
            transitionFilter?.parameters["direction"] = simd_float2(x: 0.0, y: -1.0)
        }
        transitionFilter?.duration = 1.5
        transitionFilter?.progress = 0
    }
    
    
    var currentAnim = 0,prevAnim = 0,currentImageIndex = 0
    
    override func getFrame(progress: Float) -> MTIImage? {
        
        var pause:Float = 0
        var animProgress:Float = 0
        var transitionAnimProgress:Float = 0

        
        pause = Float(1.0 / duration)
        animProgress = (Float(duration) - Float(1 * allImageUrls.count)) / Float(allImageUrls.count)
        animProgress = animProgress / Float(duration)
        transitionAnimProgress = (animProgress * 20.0 / 100.0)
        
        var start:Float = 0, end = start + animProgress
        var tStart = end + pause, tEnd = tStart + transitionAnimProgress

        let imageIndex = Int(progress / (end + pause))

        start = (animProgress + pause) * Float(imageIndex)
        end = start + animProgress
        
        if progress >= start && progress <= start + transitionAnimProgress && imageIndex > 0  {
            tStart = start
            tEnd = tStart + transitionAnimProgress
        }else{
            tStart = end + pause
            tEnd = tStart + transitionAnimProgress
        }
        
        
        if imageIndex != currentImageIndex  {
            currentImageIndex = imageIndex
            print("imageIndex \(imageIndex) progress \(progress)")
            
            if imageIndex < allImageUrls.count {
                setFilterWithImage(url: allImageUrls[imageIndex])
                prevAnim = currentAnim
                currentAnim = Int.random(in: 0..<2)
                //presentTime = CMTimeAdd(presentTime, CMTime(value: 100, timescale: 1000))
            }
        }
        
        let currentAnimProgress = simd_smoothstep(start, end, progress)

        let transitionProgress = simd_smoothstep(tStart, tEnd, progress)
        //print("progress \(progress) tStart \(tStart) tEnd \(tEnd) transitionprogress \(transitionProgress)")

        if progress >= tStart && progress <= tEnd {
            
            //print("transition progress \(transitionProgress)")
            
            autoreleasepool {
                let currentFinalFrame = generateFinalFrame(bgFilter: currentFilter!, foregroundImage: currentBlendImage!, progress: currentAnimProgress, isSingle: currentAnim == 0 ? true:false)
                
                let prevFinalFrame = generateFinalFrame(bgFilter: prevFilter!, foregroundImage: prevBlendImage!, progress: 1 - currentAnimProgress, isSingle: prevAnim == 0 ? true:false)
                
                let inputImage = MTIImage(ciImage: prevFinalFrame!).oriented(.downMirrored) .unpremultiplyingAlpha()
                let destinationImage = MTIImage(ciImage: currentFinalFrame!).oriented(.downMirrored) .unpremultiplyingAlpha()
                
                transitionFilter?.inputImage = inputImage
                transitionFilter?.destImage = destinationImage
                //whiteMinimalBgFilter.outputImage!.oriented(.downMirrored)
                

                transitionFilter?.progress = progress
                
            }
            
            return transitionFilter?.outputImage

            
        }else{
            
            let currentFinalFrame = generateFinalFrame(bgFilter: currentFilter!, foregroundImage: currentBlendImage!, progress: currentAnimProgress, isSingle: currentAnim == 0 ? true:false)

            return MTIImage(ciImage: currentFinalFrame!).oriented(.downMirrored) .unpremultiplyingAlpha()

        }
        
    }
    

    
    
    func generateFinalFrame(bgFilter:BCLTransition,foregroundImage:CIImage,progress:Float,isSingle:Bool) -> CIImage? {
        bgFilter.progress = progress
        let frame = try? BCLTransition.context?.makeCIImage(from:bgFilter.outputImage!.resized(to: outputSize)!)

        let animatedBlend : CIImage!
        
        if true {

            animatedBlend = applySingleAnimation(image:foregroundImage , progress: progress, canvasSize: outputSize)

        }else{
            animatedBlend = applyDoubleAnimation(first: foregroundImage, second: foregroundImage.copy() as! CIImage, progress: progress, canvasSize: outputSize)
        }
        
        let blendFilter = CIFilter(name: "CISourceOverCompositing")
        blendFilter?.setDefaults()
        blendFilter?.setValue(animatedBlend, forKey:kCIInputImageKey)
        blendFilter?.setValue(frame, forKey: kCIInputBackgroundImageKey)
        
        return blendFilter?.outputImage
    }
    
    
    func spiralAnimation(image:CIImage,progress:Float,canvasSize:CGSize) -> CIImage? {
        let size = image.extent.size
        
        let angle = progress * 250.0
        
        let r = angle
        let x = CGFloat(r * cos(angle))
        let y  = CGFloat(r * sin(angle))
        
        print("value of angle \(angle) x \(x) y \(y)")

        
        var translateTF = CGAffineTransform(translationX:  x, y: y)

        let initialScale = 0.3
        let scaleValue = CGFloat(initialScale + (Double(progress) * (0.5 - initialScale)))

        return image.transformed(by:translateTF)
    }
    
    func applySingleAnimation(image:CIImage,progress:Float,canvasSize:CGSize) -> CIImage? {
        
        let size = image.extent.size
        var translateTF = CGAffineTransform(translationX: canvasSize.width/2 - size.width/2 , y: canvasSize.height/2 - size.height/2)
        let initialScale = 0.5
        let scaleValue = CGFloat(initialScale + (Double(progress) * (1.0 - initialScale)))
        //CGFloat(simd_clamp(progress, 0.8, 1.0))
        
        translateTF = translateTF.concatenating(CGAffineTransform(scaleX: scaleValue, y: scaleValue))

//        if scaleValue < 0.81 {
//            let translate = CGFloat(sin(progress * 15) )
//            let vibrantT = CGAffineTransform(translationX: translate, y: translate)
//            translateTF = translateTF.concatenating(vibrantT)
//        }

        
        return image.transformed(by:translateTF)

    }
    
    func applyDoubleAnimation(first:CIImage,second:CIImage,progress:Float,canvasSize:CGSize) -> CIImage? {
                
        let center = CGPoint(x: canvasSize.width/2 - first.extent.size.width/2, y: canvasSize.height/2 - first.extent.size.height/2)
        
        var translateF = CGAffineTransform(translationX: center.x  - 60 , y: center.y  - 70)
        
        let initialScale = 0.8
        let scaleF = CGFloat(initialScale + (Double(progress) * (1 - initialScale)))
        
        translateF = translateF.concatenating(CGAffineTransform(scaleX: scaleF, y: scaleF))
        
        let scaleS = CGFloat(0.5 + (Double(sin( progress * 2.5)) * (0.8 - 0.5)))
        
        var translateS = CGAffineTransform(scaleX: scaleS, y: scaleS)
        
        let translation = (85.0 + (CGFloat(cos(progress * 3.1416 * 1.5 ) + 2.33) * 0.3) * 85.0)
        print("scaleS \(scaleS) translation \(translation)")
        
        translateS = translateS.concatenating(CGAffineTransform(translationX: center.x + translation + 10, y: center.y + translation + 10 ))
        
        
        let blendFilter = CIFilter(name: "CISourceOverCompositing")

        blendFilter?.setValue(first.transformed(by:translateF), forKey:kCIInputImageKey)
        blendFilter?.setValue(second.transformed(by:translateS), forKey: kCIInputBackgroundImageKey)
        
        if let blendImage = blendFilter?.value(forKey: "outputImage") as? CIImage{
            return blendImage
        }
        
        return nil

        
    }
    
}