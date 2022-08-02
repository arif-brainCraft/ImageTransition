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
    lazy var commonProcessor = CommonImageProcessor()

    init(allImageUrls:[URL]) {
        self.allImageUrls = allImageUrls
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

        
        pauseDuration = Float(1.0 / duration)
        animDuration = (Float(duration) - Float(1 * allImageUrls.count)) / Float(allImageUrls.count)
        animDuration = animDuration / Float(duration)
        transitionAnimDuration = (animDuration * 20.0 / 100.0)
        
        var start:Float = 0, end = start + animDuration
        var tStart = end + pauseDuration, tEnd = tStart + transitionAnimDuration

        let imageIndex = Int(progress / (end + pauseDuration))

        start = (animDuration + pauseDuration) * Float(imageIndex)
        end = start + animDuration
        
        if progress >= start && progress <= start + transitionAnimDuration && imageIndex > 0  {
            tStart = start
            tEnd = tStart + transitionAnimDuration
        }else{
            tStart = end + pauseDuration
            tEnd = tStart + transitionAnimDuration
        }
        
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
