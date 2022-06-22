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

class SlideShowTemplate{
    
    var allImages:[UIImage]!

    var outputSize:CGSize!
    
    let ciContext = CIContext(options: [CIContextOption.useSoftwareRenderer: true])
    
    var writerInput:AVAssetWriterInput!
    var pixelBufferAdaptor:AVAssetWriterInputPixelBufferAdaptor!
    var pixelBufferPool:CVPixelBufferPool!
    let framePerSecond = 60.0
    
    func createVideo(allImages:[UIImage], completion:@escaping MTMovieMakerCompletion) -> Void {
        self.allImages = allImages
        
        outputSize = CGSize(width: allImages.first!.size.width, height: allImages.first!.size.width)
        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let path = documentDirectory.appendingPathComponent("slideshow.mp4").path
        let tempURL = URL(fileURLWithPath: path)
        
        //let tempURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("slideshow.mp4"))

        if FileManager.default.fileExists(atPath: tempURL.path) {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let writer = try? AVAssetWriter(outputURL: tempURL, fileType: .mp4)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: outputSize.width,
            AVVideoHeightKey: outputSize.height
        ]
        writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let attributes = sourceBufferAttributes(outputSize: outputSize)
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput,
                                                                      sourcePixelBufferAttributes: attributes)
        writer?.add(writerInput)

        guard let success = writer?.startWriting(), success == true else {
            fatalError("Can not start writing")
        }
        
        self.pixelBufferPool = pixelBufferAdaptor?.pixelBufferPool

        guard self.pixelBufferPool != nil else {
            fatalError("AVAssetWriterInputPixelBufferAdaptor pixelBufferPool empty")
        }

        writer?.startSession(atSourceTime: .zero)
        var presentTime = CMTime.zero
        
        var lastFrame:CIImage?
        
        let transformFilter = DirectionalSlide()

        
        for index in 0..<allImages.count {
            print("presentTime outer//////////////\(CMTimeGetSeconds(presentTime))")

            let image = allImages[index]
            
            let mtiImage = MTIImage(cgImage: image.cgImage!, options: [.SRGB: false]).oriented(.downMirrored)
            
            let whiteMinimalBgFilter = WhiteMinimalBgFilter()
            
            whiteMinimalBgFilter.inputImage = mtiImage
            whiteMinimalBgFilter.destImage = mtiImage
            let totalFrame = Int(whiteMinimalBgFilter.duration * framePerSecond)

            let frameDuration:Double = 1.0
            var frameBeginTime = presentTime
            
            let blendOutputImage = blendWihtBlurBackground(image: image)!
            let random = Int.random(in: 0...1)
            
            
            if Int.random(in: 0...1) == 0 {
                transformFilter.parameters["direction"] = simd_float2(x: 0.0, y: 1.0)
            }else{
                transformFilter.parameters["direction"] = simd_float2(x: 0.0, y: -1.0)
            }
            transformFilter.duration = 2.0
            

            for frameNumber in 0..<totalFrame {
                
                let progress = Float(frameNumber) / Float(totalFrame)
                
                let frameTime = CMTimeMake(value: Int64(whiteMinimalBgFilter.duration * Double(progress) * 1000), timescale: 1000)
                presentTime = CMTimeAdd(frameBeginTime, frameTime)
                print("presentTime inner \(CMTimeGetSeconds(presentTime)) progress \(progress)")
                
                let finalFrame = generateFinalFrame(bgFilter: whiteMinimalBgFilter, foregroundImage: blendOutputImage, progress: progress, isSingle: random == 0 ? true:false)
                
                if frameNumber == totalFrame - 1  {
                    lastFrame = finalFrame
                }
                
                let totalTransformFrame = Int(transformFilter.duration * framePerSecond)

                
                if index > 0 && lastFrame != nil && frameNumber < totalTransformFrame  {
                    let inputImage = MTIImage(ciImage: lastFrame!).oriented(.downMirrored) .unpremultiplyingAlpha()
                    let destinationImage = MTIImage(ciImage: finalFrame!).oriented(.downMirrored) .unpremultiplyingAlpha()
                    let progress = Float(frameNumber) / Float(totalTransformFrame)

                    applyTransformFilter(transformFilter: transformFilter, inputImage: inputImage, destinationImage: destinationImage, progress: progress, presentTime: presentTime)
                }else{
                    addBufferToPool(frame: finalFrame!, presentTime: presentTime)
                }
                

            }
            presentTime = CMTimeAdd(presentTime, CMTime(value: 100, timescale: 1000))
        }
        

        
        writerInput.markAsFinished()
        writer?.finishWriting {
            DispatchQueue.main.async {
                if let error = writer?.error {
                    print("video written failed \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("video written succesfully")
                    completion(.success(tempURL))
                }
            }
        }
        
    }
    
    func applyTransformFilter(transformFilter:BCLTransition,inputImage:MTIImage, destinationImage:MTIImage,progress:Float,presentTime:CMTime) -> Void {
        
        transformFilter.inputImage = inputImage
        transformFilter.destImage = destinationImage
        //whiteMinimalBgFilter.outputImage!.oriented(.downMirrored)
        

        transformFilter.progress = progress
//        let frameTime = CMTimeMake(value: Int64(transformFilter.duration * Double(progress) * 1000), timescale: 1000)
//        presentTime = CMTimeAdd(frameBeginTime, frameTime)
      //  print("presentTime inner /////// \(CMTimeGetSeconds(presentTime)) progress \(progress)")

        if let frame = transformFilter.outputImage {
            if let ciimage = try? BCLTransition.context?.makeCIImage(from: frame){
                addBufferToPool(frame: ciimage, presentTime: presentTime)
            }
        }
        
    }
    
    func addBufferToPool(frame:CIImage,presentTime:CMTime) -> Void {
        
        guard let pool = self.pixelBufferPool,let adapter = pixelBufferAdaptor else {
            return
        }
        
        while !writerInput.isReadyForMoreMediaData {
            Thread.sleep(forTimeInterval: 0.01)
        }
        
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        
        if let buffer = pixelBuffer{
            let mtiFrame = MTIImage(ciImage: frame)
            try? BCLTransition.context?.render(mtiFrame, to: buffer)
            adapter.append(buffer, withPresentationTime: presentTime)
            print(".", separator: " ", terminator: " ")
        }
    }
    
    func generateFinalFrame(bgFilter:BCLTransition,foregroundImage:CIImage,progress:Float,isSingle:Bool) -> CIImage? {
        bgFilter.progress = progress
        let frame = try? BCLTransition.context?.makeCIImage(from:bgFilter.outputImage!.resized(to: outputSize)!)

        let animatedBlend : CIImage!
        
        if isSingle {
            animatedBlend = applyDoubleAnimation(first: foregroundImage, second: foregroundImage.copy() as! CIImage, progress: progress, canvasSize: outputSize)

            //animatedBlend = applySingleAnimation(image:blendOutputImage , progress: progress, canvasSize: outputSize)

        }else{
            animatedBlend = applyDoubleAnimation(first: foregroundImage, second: foregroundImage.copy() as! CIImage, progress: progress, canvasSize: outputSize)
        }
        
        let blendFilter = CIFilter(name: "CISourceOverCompositing")
        blendFilter?.setDefaults()
        blendFilter?.setValue(animatedBlend, forKey:kCIInputImageKey)
        blendFilter?.setValue(frame, forKey: kCIInputBackgroundImageKey)
        
        return blendFilter?.outputImage
    }
    
    private func sourceBufferAttributes(outputSize: CGSize) -> [String: Any] {
        let attributes: [String: Any] = [
            (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA,
            (kCVPixelBufferWidthKey as String): outputSize.width,
            (kCVPixelBufferHeightKey as String): outputSize.height
        ]
        return attributes
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
