//
//  SlideShowTemplate.swift
//  ImageTransition
//
//  Created by BCL Device7 on 21/7/22.
//

import Foundation
import MetalPetal
import MTTransitions

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
