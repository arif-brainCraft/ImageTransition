//
//  GradualBoxTemplate.swift
//  ImageTransition
//
//  Created by BCL Device7 on 13/7/22.
//

import UIKit
import MetalPetal
import MTTransitions

protocol SlideShowTemplateDelegate:NSObject {
    func showImage(image:MTIImage) -> Void
}

class GradualBoxTemplate{
    

    var outputSize:CGSize!
    
    let ciContext = CIContext(options: [CIContextOption.useSoftwareRenderer: true])
    
    let framePerSecond = 40.0
    
    
    var transitionFilter:BCLTransition?
    
    var currentFilter: BCLTransition?
    var prevFilter:BCLTransition?

//    var whiteMinimalBgFilter:WhiteMinimalBgFilter?
////    var prevMinimumBgFilter:WhiteMinimalBgFilter?
//    var blendOutputImage:CIImage?
//    var prevBlendOutputImage:CIImage?
    weak var delegate:SlideShowTemplateDelegate?
    
    func setFilterWithImage(image:UIImage) -> Void {

        prevFilter = currentFilter
//        prevBlendOutputImage = blendOutputImage
//
//        blendOutputImage = blendWihtBlurBackground(image: image)!

        let mtiImage = MTIImage(cgImage: image.cgImage!, options: [.SRGB: false]).oriented(.downMirrored).resized(to: outputSize)
        
        let rand = Int.random(in: 0...2)
        
        if rand == 0 {
            currentFilter = GradualBoxBrushStroke()
        }else if rand == 1 {
            currentFilter = GradualBoxZoom()
        }else{
            currentFilter = GradualDoubleBoxZoom()
        }
        
        currentFilter?.inputImage = mtiImage
        
        if currentFilter!.isKind(of: GradualBoxBrushStroke.self) {
            let i = Int.random(in: 3..<6)
            if let url = Bundle.main.url(forResource: "b\(i)", withExtension: "png") {
                let image = loadImageFromUrl(url: url)
                let mtiStroke = MTIImage(cgImage: image.cgImage!, options: [.SRGB: false]).oriented(.downMirrored).resized(to: outputSize)
                currentFilter?.destImage = mtiStroke!.unpremultiplyingAlpha()

            }
        }else{
            currentFilter?.destImage = currentFilter?.inputImage
        }
        
        if Int.random(in: 0...1) == 0 {
            transitionFilter = BCLTransition.Effect.angular.transition
        }else{
            transitionFilter = BCLTransition.Effect.angular.transition
            transitionFilter?.duration = 1.5

        }
        
        if transitionFilter!.isKind(of: DirectionalSlide.self) {
            if Int.random(in: 0...1) == 0 {
                transitionFilter?.parameters["direction"] = simd_float2(x: 1.0, y: 0.0)
            }else{
                transitionFilter?.parameters["direction"] = simd_float2(x: -1.0, y: 0.0)
            }
        }
        
        transitionFilter?.progress = 0
    }
    
    func createVideo(allImageUrls:[URL], completion:@escaping MTMovieMakerCompletion,forExport:Bool) -> Void {
        
        guard allImageUrls.count > 0 else{return}
        var assetWriter:AssetWriter?
        
        currentFilter = GradualBoxBrushStroke()
        transitionFilter = DirectionalSlide()
        
        let firstImage = loadImageFromUrl(url: allImageUrls.first!)
        
        outputSize = CGSize(width: 1080, height: 1080)
        
        if forExport {
            assetWriter = AssetWriter(output: outputSize)
            assetWriter?.startSession()
        }
        
        var presentTime = CMTime.zero
        var imageIndex = 0
        var currentAnim = 0,prevAnim = 0
        
        // 1.0 = pause time after transition
        let duration = currentFilter!.duration * Double(allImageUrls.count) + 1.0 * Double(allImageUrls.count)
        
        let totalFrame = Int(duration * framePerSecond)
        
        let pause:Float = Float(1.0 / duration)
        var animProgress = (Float(duration) - Float(1 * allImageUrls.count)) / Float(allImageUrls.count)
        animProgress = animProgress / Float(duration)
        let transitionAnimProgress = (animProgress * 20.0 / 100.0)
        
        print("pause \(pause) animprogress \(animProgress) transitionProgress \(transitionAnimProgress)")
        setFilterWithImage(image: firstImage)
        
        var start:Float = 0, end = start + animProgress
        var tStart = end + pause, tEnd = tStart + transitionAnimProgress
        
        for frameNumber in 0..<totalFrame {
            
            let progress = Float(frameNumber) / Float(totalFrame)
            
            let frameTime = CMTimeMake(value: Int64((duration / Double( totalFrame)) * 1000.0), timescale: 1000)
            
            if progress == 0 {
                presentTime = CMTime.zero
            }else{
                presentTime = CMTimeAdd(presentTime, frameTime)
            }
            
            if progress >= end + pause  {
                
                imageIndex += 1
                
                start = (animProgress + pause) * Float(imageIndex)
                end = start + animProgress
                print("imageIndex \(imageIndex) progress \(progress)")
                
                if imageIndex < allImageUrls.count {
                    setFilterWithImage(image: loadImageFromUrl(url: allImageUrls[imageIndex]))
                    prevAnim = currentAnim
                    currentAnim = Int.random(in: 0..<2)
                    presentTime = CMTimeAdd(presentTime, CMTime(value: 100, timescale: 1000))
                }
            }
            
            
            
            let currentAnimProgress = simd_smoothstep(start, end, progress)
            print(" outer progress \(progress) start\(start) end \(end) currentAnim \(currentAnimProgress) ")
            
            
            if progress > tEnd {
                tStart = end + pause
                tEnd = tStart + transitionAnimProgress
            }
            
            autoreleasepool {
                
                if !forExport {
                    Thread.sleep(forTimeInterval: CMTimeGetSeconds(frameTime))
                }
                
                let transitionProgress = simd_smoothstep(tStart, tEnd, progress)
                if progress >= tStart && progress <= tEnd {
                    
                    print("progress \(progress) transition \(transitionProgress) currentAnim \(currentAnimProgress)")
                    currentFilter?.progress = currentAnimProgress
                    prevFilter?.progress = 1 - currentAnimProgress
                    
                    transitionFilter?.inputImage = prevFilter?.outputImage?.oriented(.downMirrored).unpremultiplyingAlpha()
                    transitionFilter?.destImage = currentFilter?.outputImage?.oriented(.downMirrored).unpremultiplyingAlpha()
                    transitionFilter?.progress = transitionProgress
                    if let finalFrame = transitionFilter?.outputImage{
                        
                        if forExport {
                            if let ciimage = try? BCLTransition.context?.makeCIImage(from: finalFrame){
                                assetWriter?.addBufferToPool(frame: ciimage, presentTime: presentTime)

                            }
                        }else{
                            self.delegate?.showImage(image: finalFrame)
                        }
                    }
                    
                }else{
                    currentFilter?.progress = currentAnimProgress
                    if let finalFrame = currentFilter?.outputImage{
                        if forExport {
                            if let ciimage = try? BCLTransition.context?.makeCIImage(from: finalFrame){
                                assetWriter?.addBufferToPool(frame: ciimage, presentTime: presentTime)
                            }
                        }else{
                            self.delegate?.showImage(image:  finalFrame)
                        }
                        
                    }
                    
                    
                }
            }
        }
        
        if forExport {
            assetWriter?.finishWriting(completion: completion)
        }else{
            completion(.success(nil))
        }

        
    }
    
    func loadImageFromUrl(url:URL) -> UIImage {
        if let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        return UIImage()
    }
    
    func applyTransformFilter(transformFilter:BCLTransition,inputImage:MTIImage, destinationImage:MTIImage,progress:Float,presentTime:CMTime) -> CIImage? {
        
        transformFilter.inputImage = inputImage
        transformFilter.destImage = destinationImage
        //whiteMinimalBgFilter.outputImage!.oriented(.downMirrored)
        

        transformFilter.progress = progress
//        let frameTime = CMTimeMake(value: Int64(transformFilter.duration * Double(progress) * 1000), timescale: 1000)
//        presentTime = CMTimeAdd(frameBeginTime, frameTime)
      //  print("presentTime inner /////// \(CMTimeGetSeconds(presentTime)) progress \(progress)")
        
        if let frame = transformFilter.outputImage {
            return try? BCLTransition.context?.makeCIImage(from: frame)
        }
        
        return nil
        
    }
    
    func generateFinalFrame(bgFilter:BCLTransition,foregroundImage:CIImage,progress:Float,isSingle:Bool) -> CIImage? {
        
        guard let bgImage = bgFilter.outputImage else {
            return CIImage()
        }
        
        bgFilter.progress = progress
        let frame = try? BCLTransition.context?.makeCIImage(from:bgImage.resized(to: outputSize)!)

        let animatedBlend : CIImage!
        
        if true {

            //animatedBlend = applySingleAnimation(image:foregroundImage , progress: progress, canvasSize: outputSize)
            animatedBlend = spiralAnimation(image: foregroundImage, progress: progress, canvasSize: outputSize)

        }else{
            animatedBlend = applyDoubleAnimation(first: foregroundImage, second: foregroundImage.copy() as! CIImage, progress: progress, canvasSize: outputSize)
        }
        
        let blendFilter = CIFilter(name: "CISourceOverCompositing")
        blendFilter?.setDefaults()
        blendFilter?.setValue(animatedBlend, forKey:kCIInputImageKey)
        blendFilter?.setValue(frame, forKey: kCIInputBackgroundImageKey)
        
        return frame
    }
    

    
    func changeOpacity(image:CIImage, value:CGFloat) -> CIImage? {
        
        let rgba:[CGFloat] = [0.0, 0.0, 0.0, value]

        let colorMatrix = CIFilter(name: "CIColorMatrix")

        colorMatrix?.setDefaults()
        colorMatrix?.setValue(image, forKey: kCIInputImageKey)
        colorMatrix?.setValue(CIVector(values: rgba, count: 4), forKey: "inputAVector")
        return colorMatrix?.outputImage
    }
    
    func blendWihtBlurBackground(image:UIImage) -> CIImage? {
        
        let imageSize = image.size

        guard let ciimage = CIImage(image: image) else{return nil}
        
        let clampFilter = CIFilter(name: "CIAffineClamp")
        clampFilter?.setDefaults()
        clampFilter?.setValue(ciimage, forKey: kCIInputImageKey)
        let scaleTB = CGAffineTransform(scaleX: 0.6, y: 0.7)
        
        let gaussianBlurFilter = CIFilter(name:"CIGaussianBlur")
        gaussianBlurFilter?.setValue(clampFilter?.outputImage?.transformed(by:scaleTB ), forKey: kCIInputImageKey)
        gaussianBlurFilter?.setValue(10, forKey: kCIInputRadiusKey)
        
        let scaleTF = CGAffineTransform(scaleX: 0.6, y: 0.4)
        let bgSize = __CGSizeApplyAffineTransform(imageSize, scaleTB)
        let foreSize = __CGSizeApplyAffineTransform(imageSize, scaleTF)
        
        let blurOutput = gaussianBlurFilter?.outputImage?.cropped(to: CGRect(x: 0, y: 0, width: bgSize.width, height: bgSize.height))
        
        //let opacity = CGFloat(sinf(progress * 3.1416 * 3  + 4.7) * 0.5 + 0.5)

        let blendFilter = CIFilter(name: "CISourceOverCompositing")
        let scaledCiImage = ciimage.transformed(by:scaleTF ).transformed(by:CGAffineTransform(translationX:  bgSize.width/2 - foreSize.width/2, y: bgSize.height/2 - foreSize.height/2))

        blendFilter?.setValue(scaledCiImage, forKey:kCIInputImageKey)
        blendFilter?.setValue(blurOutput, forKey: kCIInputBackgroundImageKey)
        
        if let blendImage = blendFilter?.value(forKey: "outputImage") as? CIImage{
            return blendImage
        }
        return nil
    }
    
    func spiralAnimation(image:CIImage,progress:Float,canvasSize:CGSize) -> CIImage? {
        let size = image.extent.size
        
        let angle = progress * 250.0
        
        let r = angle
        let x = CGFloat(r * cos(angle))
        let y  = CGFloat(r * sin(angle))
        
        //print("value of angle \(angle) x \(x) y \(y)")

        
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
    
    
    func resizeImage(sourceImage:CIImage,targetSize:CGSize) -> CIImage? {
        
        let resizeFilter = CIFilter(name:"CILanczosScaleTransform")!

        // Desired output size

        // Compute scale and corrective aspect ratio
        let scale = targetSize.height / sourceImage.extent.height
        let aspectRatio = targetSize.width/(sourceImage.extent.width * scale)

        // Apply resizing
        resizeFilter.setValue(sourceImage, forKey: kCIInputImageKey)
        resizeFilter.setValue(scale, forKey: kCIInputScaleKey)
        resizeFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
        return resizeFilter.outputImage
    }
}
