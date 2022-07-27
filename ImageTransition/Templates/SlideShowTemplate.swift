//
//  SlideShowTemplate.swift
//  ImageTransition
//
//  Created by BCL Device7 on 21/7/22.
//

import Foundation
import MetalPetal
import MTTransitions
import CoreMedia

protocol SlideShowTemplateDelegate:NSObject {
    func showImage(image:MTIImage) -> Void
}

class SlideShowTemplate{
    
    var outputSize:CGSize!
    let framePerSecond = 40.0
    var isStopped = false
    var forExport = false
    var duration:Double!
    //let ciContext = CIContext(options: [CIContextOption.useSoftwareRenderer: true])
    weak var delegate:SlideShowTemplateDelegate?
    var allImageUrls = [URL]()
    var displayCount = 0
    
    init(allImageUrls:[URL],forExport:Bool) {
        self.forExport = forExport
        self.allImageUrls = allImageUrls
    }
    
    func start(completion:@escaping MTMovieMakerCompletion) -> Void {
        
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
    
    func blendWihtBlurBackground(image:UIImage,bRatio:(x:CGFloat, y: CGFloat), fRatio:(x:CGFloat, y: CGFloat)) -> CIImage? {
        
        let imageSize = image.size

        guard let ciimage = CIImage(image: image) else{return nil}
        
        let clampFilter = CIFilter(name: "CIAffineClamp")
        clampFilter?.setDefaults()
        clampFilter?.setValue(ciimage, forKey: kCIInputImageKey)
        let scaleTB = CGAffineTransform(scaleX: bRatio.x, y: bRatio.y)
        
        let gaussianBlurFilter = CIFilter(name:"CIGaussianBlur")
        gaussianBlurFilter?.setValue(clampFilter?.outputImage?.transformed(by:scaleTB ), forKey: kCIInputImageKey)
        gaussianBlurFilter?.setValue(10, forKey: kCIInputRadiusKey)
        
        let scaleTF = CGAffineTransform(scaleX: fRatio.x, y: fRatio.y)
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
    
    func changeOpacity(image:CIImage, value:CGFloat) -> CIImage? {
        
        let rgba:[CGFloat] = [0.0, 0.0, 0.0, value]

        let colorMatrix = CIFilter(name: "CIColorMatrix")

        colorMatrix?.setDefaults()
        colorMatrix?.setValue(image, forKey: kCIInputImageKey)
        colorMatrix?.setValue(CIVector(values: rgba, count: 4), forKey: "inputAVector")
        return colorMatrix?.outputImage
    }
    
    func increaseDisplayCount() -> Void {
        self.displayCount += 1
    }
    func reset() -> Void {
        self.displayCount = 0
    }
    
    func getProgress() -> Float {
        return Float(displayCount) / (Float(duration) * Float(framePerSecond))
    }
}
