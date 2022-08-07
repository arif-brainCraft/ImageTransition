//
//  SlideShowTemplate.swift
//  ImageTransition
//
//  Created by BCL Device7 on 21/7/22.
//

import Foundation
import MetalPetal
import MTTransitions

struct Schedule {
    var start:Float
    var end:Float
    var tStart:Float
    var tEnd:Float
    var imageIndex:Int
    
    var pauseDuration:Float
    var animDuration:Float
    var transitionAnimDuration:Float
}

protocol SlideShowTemplateDelegate:NSObject {
    func showImage(image:MTIImage) -> Void
}

class SlideShowTemplate{
    
    
    var outputSize:CGSize!
    let framePerSecond = 40.0
    var isStopped = false
    var duration:Double!
    //let ciContext = CIContext(options: [CIContextOption.useSoftwareRenderer: true])
    weak var delegate:SlideShowTemplateDelegate?
    var allImageUrls = [URL]()
    private var displayCount = 0
    private var transitionOutTime:Double = 0.0
    private var pauseTime:Double = 0.0

    lazy var commonProcessor = CommonImageProcessor()

    var transitionFilter:BCLTransition?
    
    var currentFilter: BCLTransition?
    var prevFilter:BCLTransition?
    
    init(allImageUrls:[URL]) {
        self.allImageUrls = allImageUrls

    }
    
    func calculateDuration(pauseTime:Double,transitionOutTime:Double) -> Void {
        self.duration = currentFilter!.duration * Double(allImageUrls.count) + pauseTime * Double(allImageUrls.count)
        if transitionOutTime < transitionFilter?.duration ?? 0.0 {
            self.duration += transitionOutTime * Double(allImageUrls.count - 1)
        }
        self.pauseTime = pauseTime
        self.transitionOutTime = transitionOutTime
    }
    
    func start(forExport:Bool,completion:@escaping MTMovieMakerCompletion) -> Void {
        
        var assetWriter:AssetWriter?

        if forExport {
            assetWriter = AssetWriter(output: outputSize)
            assetWriter?.startSession()
        }
        
        let totalFrame = Int(duration * framePerSecond)
        var presentTime = CMTime.zero

        for frameNumber in 0..<totalFrame {
            
            let progress = Float(frameNumber) / Float(totalFrame)
            
            let frameTime = CMTimeMake(value: Int64((duration / Double( totalFrame)) * 1000.0), timescale: 1000)
            
            if progress == 0 {
                presentTime = CMTime.zero
            }else{
                presentTime = CMTimeAdd(presentTime, frameTime)
            }


            if !forExport {
                Thread.sleep(forTimeInterval: CMTimeGetSeconds(frameTime))
            }
            
            autoreleasepool {
                if let finalFrame = getFrame(progress: progress){
                    if forExport {
                        if let ciimage = try? BCLTransition.context?.makeCIImage(from: finalFrame){
                            assetWriter?.addBufferToPool(frame: ciimage, presentTime: presentTime)
                        }
                    }else{
                        //self.delegate?.showImage(image:  finalFrame.resized(to: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width))!)
                        self.delegate?.showImage(image:  finalFrame)

                    }
                }else{
                    presentTime = CMTimeAdd(presentTime, CMTime(value: 100, timescale: 1000))
                }
            }
            
        }
        
        if forExport {
            assetWriter?.finishWriting(completion: completion)
        }else{
            completion(.success(nil))
        }

    }
    
    func getFrame(progress:Float) -> MTIImage? {
        //must override this method and return appropriate frame
        return nil
    }
    
    func getSchedule(progress:Float) -> Schedule {
        var pauseDuration:Float = 0
        var animDuration:Float = 0
        var transitionAnimDuration:Float = 0
        var transitionIn:Float = 0
        var transitionOut:Float = 0
        
        let tempDuration = duration - transitionOutTime * Double(allImageUrls.count - 1)
        
        pauseDuration = Float(pauseTime / duration)
        animDuration = (Float(duration) - Float(pauseTime * Double(allImageUrls.count)) - Float(transitionOutTime * Double(allImageUrls.count - 1))) / Float(allImageUrls.count)
        animDuration = animDuration / Float(duration)
        
        transitionAnimDuration = Float((transitionFilter?.duration ?? 0.0) / duration) //(animDuration * 30.0 / 100.0)
        transitionIn = Float(((transitionFilter?.duration ?? 0.0) - transitionOutTime) / duration) / 2.0
        transitionOut = Float(transitionOutTime / duration)
        
        var start:Float = 0, end = start + animDuration
        var tStart = end + pauseDuration - transitionIn, tEnd = tStart + transitionAnimDuration

        var imageIndex = Int(progress / (end + pauseDuration + transitionOut ))


        start = (animDuration + pauseDuration + transitionOut) * Float(imageIndex)
        end = start + animDuration

        if progress >= (end + pauseDuration - transitionIn) {
            imageIndex += 1
            if imageIndex < allImageUrls.count {
                start = (animDuration + pauseDuration + transitionOut) * Float(imageIndex)
                end = start + animDuration
            }
            
        }
        
        if imageIndex < allImageUrls.count {
            if progress >= start - transitionIn - transitionOut && progress <= start - transitionIn + transitionAnimDuration && imageIndex > 0  {
                tStart = start - transitionIn - transitionOut
            }else{
                tStart = end + pauseDuration - transitionIn
            }
        }
        
        tEnd = tStart + transitionAnimDuration

        
        print("progress \(progress) image \(imageIndex) start \(start) End \(end)")
        //print("progress \(progress) tStart \(tStart) tEnd \(tEnd)")
        
        return Schedule(start: start, end: end, tStart: tStart, tEnd: tEnd, imageIndex: imageIndex, pauseDuration: pauseDuration, animDuration: animDuration,transitionAnimDuration: transitionAnimDuration)
    }
    
    func stopCreatingVideo() -> Void {
        self.isStopped = true
    }
    
    func loadImageFromUrl(url:URL) -> UIImage {
        if let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        return UIImage()
    }
    
    
    func increaseDisplayCount() -> Void {
        self.displayCount += 1
    }
    func reset() -> Void {
        self.displayCount = 0
    }
    
    func getProgress() -> Float {
        return Float(self.displayCount) / (Float(self.duration) * Float(self.framePerSecond))
    }
}
