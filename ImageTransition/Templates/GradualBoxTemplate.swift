//
//  GradualBoxTemplate.swift
//  ImageTransition
//
//  Created by BCL Device7 on 13/7/22.
//

import UIKit
import MetalPetal
import MTTransitions



class GradualBoxTemplate:SlideShowTemplate{

    var transitionFilter:BCLTransition?
    
    var currentFilter: BCLTransition?
    var prevFilter:BCLTransition?

    override init(allImageUrls: [URL], forExport: Bool) {
        super.init(allImageUrls: allImageUrls, forExport: forExport)
        outputSize = CGSize(width: 1080, height: 1080)
        setFilterWithImage(url: allImageUrls.first!)

        self.duration = currentFilter!.duration * Double(allImageUrls.count) + 1.0 * Double(allImageUrls.count)

    }
    
    func setFilterWithImage(url:URL) -> Void {
        
        prevFilter = currentFilter
        
        let mtiImage = MTIImage(contentsOf: url, size: outputSize, options: [.SRGB:false], alphaType: .nonPremultiplied)
        //MTIImage(cgImage: image.cgImage!, options: [.SRGB: false]).oriented(.downMirrored).resized(to: outputSize)?.unpremultiplyingAlpha()
        
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
                //let image = loadImageFromUrl(url: url)
                let mtiStroke = MTIImage(contentsOf: url, size: CGSize(width: outputSize.width - 160, height: outputSize.height - 160), options: [.SRGB:false], alphaType: .nonPremultiplied)
                //MTIImage(cgImage: image.cgImage!, options: [.SRGB: false]).oriented(.downMirrored).resized(to: outputSize)?.unpremultiplyingAlpha()
                currentFilter?.destImage = mtiStroke
                
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
    
//    func createVideo(allImageUrls:[URL], completion:@escaping MTMovieMakerCompletion,forExport:Bool) -> Void {
//
//        guard allImageUrls.count > 0 else{return}
//        var assetWriter:AssetWriter?
//
//        currentFilter = GradualBoxBrushStroke()
//        transitionFilter = DirectionalSlide()
//
//        let firstImage = loadImageFromUrl(url: allImageUrls.first!)
//
//        outputSize = CGSize(width: 1080, height: 1080)
//
//
//
//        var presentTime = CMTime.zero
//        var imageIndex = 0
//        var currentAnim = 0,prevAnim = 0
//
//        // 1.0 = pause time after transition
//        let duration = currentFilter!.duration * Double(allImageUrls.count) + 1.0 * Double(allImageUrls.count)
//
//        let totalFrame = Int(duration * framePerSecond)
//
//
//        for frameNumber in 0..<totalFrame {
//
//            let progress = Float(frameNumber) / Float(totalFrame)
//
//            let frameTime = CMTimeMake(value: Int64((duration / Double( totalFrame)) * 1000.0), timescale: 1000)
//
//            if progress == 0 {
//                presentTime = CMTime.zero
//            }else{
//                presentTime = CMTimeAdd(presentTime, frameTime)
//            }
//
//            if progress >= end + pause  {
//
//                imageIndex += 1
//
//                start = (animProgress + pause) * Float(imageIndex)
//                end = start + animProgress
//                print("imageIndex \(imageIndex) progress \(progress)")
//
//                if imageIndex < allImageUrls.count {
//                    setFilterWithImage(image: loadImageFromUrl(url: allImageUrls[imageIndex]))
//                    prevAnim = currentAnim
//                    currentAnim = Int.random(in: 0..<2)
//                    presentTime = CMTimeAdd(presentTime, CMTime(value: 100, timescale: 1000))
//                }
//            }
//
//
//
//            let currentAnimProgress = simd_smoothstep(start, end, progress)
//            print(" outer progress \(progress) start\(start) end \(end) currentAnim \(currentAnimProgress) ")
//
//
//            if progress > tEnd {
//                tStart = end + pause
//                tEnd = tStart + transitionAnimProgress
//            }
//
//            if !forExport {
//                Thread.sleep(forTimeInterval: CMTimeGetSeconds(frameTime))
//            }
//            if self.isStopped {
//                break
//            }
//
//            autoreleasepool {
//
//
//                let transitionProgress = simd_smoothstep(tStart, tEnd, progress)
//                if progress >= tStart && progress <= tEnd {
//
//                    print("progress \(progress) transition \(transitionProgress) currentAnim \(currentAnimProgress)")
//                    currentFilter?.progress = currentAnimProgress
//                    prevFilter?.progress = 1 - currentAnimProgress
//
//                    transitionFilter?.inputImage = prevFilter?.outputImage?.oriented(.downMirrored).unpremultiplyingAlpha()
//                    transitionFilter?.destImage = currentFilter?.outputImage?.oriented(.downMirrored).unpremultiplyingAlpha()
//                    transitionFilter?.progress = transitionProgress
//                    if let finalFrame = transitionFilter?.outputImage{
//
//
//                    }
//
//                }else{
//                    currentFilter?.progress = currentAnimProgress
//                    if let finalFrame = currentFilter?.outputImage{
//
//
//                    }
//
//
//                }
//            }
//        }
//    }
    
    var currentAnim = 0,prevAnim = 0,currentImageIndex = 0
    
    override func getFrame(progress: Float) -> MTIImage? {
        
        var pause:Float = 0
        var animProgress:Float = 0
        var transitionAnimProgress:Float = 0

        if progress == 0 {
            //print("pause \(pause) animprogress \(animProgress) transitionProgress \(transitionAnimProgress)")

        }
        
        
        pause = Float(1.0 / duration)
        animProgress = (Float(duration) - Float(1 * allImageUrls.count)) / Float(allImageUrls.count)
        animProgress = animProgress / Float(duration)
        transitionAnimProgress = (animProgress * 20.0 / 100.0)
        
        var start:Float = 0, end = start + animProgress
        var tStart = end + pause, tEnd = tStart + transitionAnimProgress

        let imageIndex = Int(progress / (end + pause))
        let tIndex = Int(progress / (end + pause + transitionAnimProgress))

        start = (animProgress + pause) * Float(imageIndex)
        end = start + animProgress
        
        
        tStart = (animProgress + pause) * Float(tIndex) + animProgress + pause
        tEnd = tStart + transitionAnimProgress
        
//        if progress > tEnd {
//            tStart = start + pause
//            tEnd = tStart + transitionAnimProgress
//        }
        

        
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
       // print(" outer progress \(progress) start\(start) end \(end) currentAnim \(currentAnimProgress) ")
        
//        if progress > tEnd {
//            tStart = end + pause
//            tEnd = tStart + transitionAnimProgress
//        }
        

        
        let transitionProgress = simd_smoothstep(tStart, tEnd, progress)
        //print("progress \(progress) tStart \(tStart) tEnd \(tEnd) transitionprogress \(transitionProgress) tIndex \(tIndex)")

        //print("progress \(progress) transitionprogress \(transitionProgress)")

        if progress >= tStart && progress <= tEnd {
            
            //print("transition progress \(transitionProgress)")
            
            autoreleasepool {
                currentFilter?.progress = currentAnimProgress
                prevFilter?.progress = 1 - currentAnimProgress
                
                transitionFilter?.inputImage = prevFilter?.outputImage
                transitionFilter?.destImage = currentFilter?.outputImage
                transitionFilter?.progress = transitionProgress
            }
            
            return transitionFilter?.outputImage

            
        }else{
            currentFilter?.progress = currentAnimProgress
            return currentFilter?.outputImage?.oriented(.downMirrored)

        }
        
    }
    
}
