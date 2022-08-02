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

    fileprivate var transitionFilter:BCLTransition?
    
    fileprivate var currentFilter: BCLTransition?
    fileprivate var prevFilter:BCLTransition?

    override init(allImageUrls: [URL]) {
        super.init(allImageUrls: allImageUrls)
        outputSize = CGSize(width: 1080, height: 1080)
        setFilterWithImage(url: allImageUrls.first!)

        self.duration = currentFilter!.duration * Double(allImageUrls.count) + 1.0 * Double(allImageUrls.count)

    }
    
    func setFilterWithImage(url:URL) -> Void {
        
        prevFilter = currentFilter
        
        let mtiImage = MTIImage(contentsOf: url, size: outputSize, options: [.SRGB:false], alphaType: .nonPremultiplied)
        
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
                let mtiStroke = MTIImage(contentsOf: url, size: CGSize(width: outputSize.width - 160, height: outputSize.height - 160), options: [.SRGB:false], alphaType: .nonPremultiplied)
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
        
        let currentAnimProgress = simd_smoothstep(schedule.start, schedule.end, progress)

        let transitionProgress = simd_smoothstep(schedule.tStart, schedule.tEnd, progress)
        //print("progress \(progress) tStart \(tStart) tEnd \(tEnd) transitionprogress \(transitionProgress)")

        if progress >= schedule.tStart && progress <= schedule.tEnd {
            
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
