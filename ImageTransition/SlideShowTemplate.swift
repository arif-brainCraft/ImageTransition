//
//  SlideShowTemplate.swift
//  ImageTransition
//
//  Created by BCL Device7 on 14/6/22.
//

import UIKit
import MetalPetal
import CoreImage

class SlideShowTemplate{
    
    var allImages:[UIImage]!
    let whiteMinimalBgFilter = WhiteMinimalBgFilter()
    //let blurFilter = MTIMPSGaussianBlurFilter()
    let gaussianBlurFilter = CIFilter(name:"CIGaussianBlur")

    let blendFilter = CIFilter(name: "CISourceOverCompositing")
    let blendFilter2 = CIFilter(name: "CISourceOverCompositing")

    let transformFilter = MTITransformFilter()
    

    
    func createVideo(allImages:[UIImage], completion:@escaping MTMovieMakerCompletion) -> Void {
        self.allImages = allImages
        let image = allImages.first!
        
        let outputSize = image.size
        
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
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let attributes = sourceBufferAttributes(outputSize: outputSize)
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput,
                                                                      sourcePixelBufferAttributes: attributes)
        writer?.add(writerInput)

        guard let success = writer?.startWriting(), success == true else {
            fatalError("Can not start writing")
        }
        
        guard let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool else {
            fatalError("AVAssetWriterInputPixelBufferAdaptor pixelBufferPool empty")
        }
        
        writer?.startSession(atSourceTime: .zero)
        
        let mtiImage = MTIImage(cgImage: allImages.first!.cgImage!, options: [.SRGB: false]).oriented(.downMirrored)
        

        whiteMinimalBgFilter.inputImage = mtiImage
        whiteMinimalBgFilter.destImage = mtiImage
        let totalFrame = Int(whiteMinimalBgFilter.duration * 20)
        let frameDuration:Double = 1.0
        var presentTime = CMTimeMake(value: Int64(frameDuration * Double(0) * 1000), timescale: 1000)
        let frameBeginTime = presentTime
        
        
        let imageSize = image.size
//        let resizedImage = image.resized(to: CGSize(width: imageSize.width * 0.6, height: imageSize.height * 0.6))
        
        guard let ciimage = CIImage(image: image) else{return}
        
        let scaleTB = CGAffineTransform(scaleX: 0.7, y: 0.7)
        gaussianBlurFilter?.setValue(ciimage.transformed(by:scaleTB ), forKey: kCIInputImageKey)
        gaussianBlurFilter?.setValue(15, forKey: kCIInputRadiusKey)
        
        blendFilter?.setDefaults()
        
        let scaleTF = CGAffineTransform(scaleX: 0.6, y: 0.5)
        let bgSize = __CGSizeApplyAffineTransform(imageSize, scaleTB)
        let foreSize = __CGSizeApplyAffineTransform(imageSize, scaleTF)
        
        let scaledCiImage = ciimage.transformed(by:scaleTF )
        blendFilter?.setValue(scaledCiImage.transformed(by:CGAffineTransform(translationX:  bgSize.width/2 - foreSize.width/2, y: bgSize.height/2 - foreSize.height/2)), forKey:kCIInputImageKey)
        blendFilter?.setValue(gaussianBlurFilter?.outputImage, forKey: kCIInputBackgroundImageKey)
        
        var blendOutputImage = blendFilter?.value(forKey: "outputImage") as? CIImage
        
        
        for frameNumber in 0..<totalFrame {
            let progress = Float(frameNumber) / Float(totalFrame)
            whiteMinimalBgFilter.progress = progress
            
            let frameTime = CMTimeMake(value: Int64(whiteMinimalBgFilter.duration * Double(progress) * 1000), timescale: 1000)
            presentTime = CMTimeAdd(frameBeginTime, frameTime)
            
            let bgImage = whiteMinimalBgFilter.outputImage!
            
            
            var translateTF = CGAffineTransform(translationX: imageSize.width/2 - bgSize.width/2, y: imageSize.height/2 - bgSize.height/2)
            let scaleValue = CGFloat(simd_clamp(progress, 0.6, 1.0))
            

            translateTF = translateTF.concatenating(CGAffineTransform(scaleX: scaleValue, y: scaleValue))

            if scaleValue < 0.61 {
                let translate = CGFloat(sin(progress * 15) )
                let vibrantT = CGAffineTransform(translationX: translate, y: translate)
                translateTF = translateTF.concatenating(vibrantT)
            }

            
            let frame = try? BCLTransition.context?.makeCIImage(from:bgImage)//.transformed(by:translateTB)

            
            blendFilter2?.setDefaults()
            blendFilter2?.setValue(blendOutputImage?.transformed(by:translateTF), forKey:kCIInputImageKey)
            blendFilter2?.setValue(frame, forKey: kCIInputBackgroundImageKey)

            
            while !writerInput.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.01)
            }
            
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
            
            if let buffer = pixelBuffer,let frame = blendFilter2?.outputImage {
                let mtiFrame = MTIImage(ciImage: frame)
                try? BCLTransition.context?.render(mtiFrame, to: buffer)
                pixelBufferAdaptor.append(buffer, withPresentationTime: presentTime)
                print(".", separator: " ", terminator: " ")

            }

            

            
            
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
    
    private func sourceBufferAttributes(outputSize: CGSize) -> [String: Any] {
        let attributes: [String: Any] = [
            (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA,
            (kCVPixelBufferWidthKey as String): outputSize.width,
            (kCVPixelBufferHeightKey as String): outputSize.height
        ]
        return attributes
    }
    
    
    
}
