//
//  CombineTransitionMovieMaker.swift
//  ImageTransition
//
//  Created by BCL Device7 on 28/4/22.
//

import UIKit
import MetalPetal

public enum MTMovieMakerError: Error {
    case imagesMustMoreThanTwo
    case imagesAndEffectsDoesNotMatch
}

public typealias MTMovieMakerProgressHandler = (Float) -> Void

public typealias MTMovieMakerCompletion = (Result<URL, Error>) -> Void

class CombineTransitionMovieMaker:NSObject {
    
    private var writer: AVAssetWriter?
    
    private let outputURL: URL
    
    private let writingQueue: DispatchQueue
    
    private var exportSession: AVAssetExportSession?
    lazy var mtiContext = try? MTIContext(device: MTLCreateSystemDefaultDevice()!)
    public init(outputURL: URL) {
        self.outputURL = outputURL
        self.writingQueue = DispatchQueue(label: "me.shuifeng.MTTransitions.MovieWriter.writingQueue")
        super.init()
    }
    
    
    public func createCombinedTransitionVideo(with images: [UIImage],
                            effects: [BCLTransition.Effect],
                            blendEffects:[Int],
                            frameDuration: TimeInterval = 1,
                            transitionDuration: TimeInterval = 0.8,
                            audioURL: URL? = nil,
                            completion: @escaping MTMovieMakerCompletion) throws {
        
        
        let inputImages = images.map {
            return MTIImage(cgImage: $0.cgImage!, options: [.SRGB: false]).oriented(.downMirrored)
        }
        try createCombinedTransitionVideo(with: inputImages,
                        effects: effects,
                        blendEffects:blendEffects,
                        frameDuration: frameDuration,
                        transitionDuration: transitionDuration,
                        audioURL: audioURL,
                        completion: completion)
    }
    
    public func createCombinedTransitionVideo(with images: [MTIImage],
                            effects: [BCLTransition.Effect],
                            blendEffects:[Int],
                            frameDuration: TimeInterval = 1,
                            transitionDuration: TimeInterval = 0.8,
                            audioURL: URL? = nil,
                            completion: MTMovieMakerCompletion? = nil) throws {
        
        guard images.count >= 2 else {
            print("ERROR:: imagesMustMoreThanTwo")

            throw MTMovieMakerError.imagesMustMoreThanTwo
        }
        
        let totalEffect = effects.count - blendEffects.count
        
        guard totalEffect == images.count - 1 else {
            print("ERROR:: imagesAndEffectsDoesNotMatch")
            throw MTMovieMakerError.imagesAndEffectsDoesNotMatch
        }
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let outputSize = images.first!.size
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
        
        self.writer?.startSession(atSourceTime: .zero)
        writerInput.requestMediaDataWhenReady(on: self.writingQueue) {
            var index = 0,effectIndex = 0
            while index < (images.count - 1) {
                var presentTime = CMTimeMake(value: Int64(frameDuration * Double(index) * 1000), timescale: 1000)
                let transition = effects[effectIndex].transition
                transition.inputImage = images[index]
                transition.destImage = images[index + 1]
                transition.duration = transitionDuration

                let frameBeginTime = presentTime
                let frameCount = 60
                                
                for counter in 0 ... frameCount {
                    autoreleasepool {
                        while !writerInput.isReadyForMoreMediaData {
                            Thread.sleep(forTimeInterval: 0.01)
                        }
                        let progress = Float(counter) / Float(frameCount)
                        transition.progress = progress
                        let frameTime = CMTimeMake(value: Int64(transitionDuration * Double(progress) * 1000), timescale: 1000)
                        presentTime = CMTimeAdd(frameBeginTime, frameTime)

                        if  let frame = transition.outputImage {
                            if blendEffects.contains(effectIndex + 1) {
                                
                                let transition2 = effects[effectIndex + 1].transition
                                transition2.progress = transition.progress;
                                transition2.inputImage = frame.oriented(.downMirrored)
                                transition2.destImage = transition.destImage
                                transition2.duration = transition.duration
                                
                                var pixelBuffer: CVPixelBuffer?
                                CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
                                
                                if let buffer = pixelBuffer,let frame = transition2.outputImage {
                                    
                                    try? BCLTransition.context?.render(frame, to: buffer)
                                    pixelBufferAdaptor.append(buffer, withPresentationTime: presentTime)
                                }
                                
                            }else{
                                var pixelBuffer: CVPixelBuffer?
                                CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
                                
                                if let buffer = pixelBuffer,let frame = transition.outputImage {
                                    try? BCLTransition.context?.render(frame, to: buffer)
                                    pixelBufferAdaptor.append(buffer, withPresentationTime: presentTime)
                                }
                            }
                            
                            
                        }
                    }
                }
                index += 1
                
                if blendEffects.contains(effectIndex + 1) {
                    effectIndex += 1
                }
                effectIndex += 1

            }
            
            writerInput.markAsFinished()
            self.writer?.finishWriting {
                if let audioURL = audioURL, self.writer?.error == nil {
                    do {
                        let audioAsset = AVAsset(url: audioURL)
                        let videoAsset = AVAsset(url: self.outputURL)
                        try self.mixAudio(audioAsset, video: videoAsset, completion: completion)
                    } catch {
                        completion?(.failure(error))
                    }
                } else {
                    DispatchQueue.main.async {
                        if let error = self.writer?.error {
                            print("video written failed")
                            completion?(.failure(error))
                        } else {
                            print("video written succesfully")
                            completion?(.success(self.outputURL))
                        }
                    }
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
    
    private func mixAudio(_ audio: AVAsset, video: AVAsset, completion: MTMovieMakerCompletion? = nil) throws {
        guard let videoTrack = video.tracks(withMediaType: .video).first else {
            fatalError("Can not found videoTrack in Video File")
        }
        guard let audioTrack = audio.tracks(withMediaType: .audio).first else {
            fatalError("Can not found audioTrack in Audio File")
        }
        
        let composition = AVMutableComposition()
        guard let videoComposition = composition.addMutableTrack(withMediaType: .video, preferredTrackID: CMPersistentTrackID(1)),
            let audioComposition = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID(2)) else {
            return
        }
        
        let videoTimeRange = CMTimeRange(start: .zero, duration: video.duration)
        try videoComposition.insertTimeRange(videoTimeRange, of: videoTrack, at: .zero)
        
        if video.duration > audio.duration {
            let repeatCount = Int(video.duration.seconds / audio.duration.seconds)
            let remain = video.duration.seconds.truncatingRemainder(dividingBy: audio.duration.seconds)
            let audioTimeRange = CMTimeRange(start: .zero, duration: audio.duration)
            for i in 0 ..< repeatCount {
                let start = CMTime(seconds: Double(i) * audio.duration.seconds, preferredTimescale: audio.duration.timescale)
                try audioComposition.insertTimeRange(audioTimeRange, of: audioTrack, at: start)
            }
            if remain > 0 {
                let startSeconds = Double(repeatCount) * audio.duration.seconds
                let start = CMTime(seconds: startSeconds, preferredTimescale: audio.duration.timescale)
                let remainDuration = CMTime(seconds: remain, preferredTimescale: audio.duration.timescale)
                let remainTimeRange = CMTimeRange(start: .zero, duration: remainDuration)
                try audioComposition.insertTimeRange(remainTimeRange, of: audioTrack, at: start)
            }
        } else {
            let audioTimeRange = CMTimeRangeMake(start: .zero, duration: video.duration)
            try audioComposition.insertTimeRange(audioTimeRange, of: audioTrack, at: .zero)
        }
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("temp.mp4"))
        try? FileManager.default.removeItem(at: tempURL)
        exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputFileType = .mp4
        exportSession?.outputURL = tempURL
        exportSession?.timeRange = videoTimeRange
        exportSession?.exportAsynchronously { [weak self] in
            guard let self = self, let exporter = self.exportSession else { return }
            DispatchQueue.main.async {
                if let error = exporter.error {
                    completion?(.failure(error))
                } else {
                    do {
                        if FileManager.default.fileExists(atPath: self.outputURL.path) {
                            try FileManager.default.removeItem(at: self.outputURL)
                        }
                        try FileManager.default.moveItem(at: tempURL, to: self.outputURL)
                        completion?(.success(self.outputURL))
                    } catch {
                        completion?(.failure(error))
                    }
                }
            }
        }
    }
    
        func removeFileAtURLIfExists(url: NSURL) {
            if let filePath = url.path {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: filePath) {
                    do{
                        try fileManager.removeItem(atPath: filePath)
                    } catch let error as NSError {
                        print("Couldn't remove existing destination file: \(error)")
                    }
                }
            }
        }
    
    func exportVideoWithAnimation(asset:AVAsset,audioIsEnabled:Bool = false,completion: MTMovieMakerCompletion? = nil) {
        let composition = AVMutableComposition()
        
        let track =  asset.tracks(withMediaType: AVMediaType.video)
        let videoTrack:AVAssetTrack = track[0] as AVAssetTrack
        let timerange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
        let outputSize = videoTrack.naturalSize
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())
        
        do {
            try compositionVideoTrack?.insertTimeRange(timerange, of: videoTrack, at: CMTime.zero)
            compositionVideoTrack?.preferredTransform = videoTrack.preferredTransform
        } catch {
            print(error)
        }
        
        //if your video has sound, you don’t need to check this
        if audioIsEnabled {
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())
            
            for audioTrack in (asset.tracks(withMediaType: AVMediaType.audio)) {
                do {
                    try compositionAudioTrack?.insertTimeRange(audioTrack.timeRange, of: audioTrack, at: CMTime.zero)
                } catch {
                    print(error)
                }
            }
        }
        
        let size = videoTrack.naturalSize
        
        let videolayer = CALayer()
        videolayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        let parentlayer = CALayer()
        parentlayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentlayer.addSublayer(videolayer)
        
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //this is the animation part
        var time = [0.00001, 3, 6, 9, 12] //I used this time array to determine the start time of a frame animation. Each frame will stay for 3 secs, thats why their difference is 3
        var imgarray = [UIImage]()
        
        for image in 0...4 {
            imgarray.append(UIImage(named: "\(image).jpg")!)
            
            let nextPhoto = imgarray[image]
            
            let horizontalRatio = CGFloat(outputSize.width) / nextPhoto.size.width
            let verticalRatio = CGFloat(outputSize.height) / nextPhoto.size.height
            let aspectRatio = min(horizontalRatio, verticalRatio)
            let newSize: CGSize = CGSize(width: nextPhoto.size.width * aspectRatio, height: nextPhoto.size.height * aspectRatio)
            let x = newSize.width < outputSize.width ? (outputSize.width - newSize.width) / 2 : 0
            let y = newSize.height < outputSize.height ? (outputSize.height - newSize.height) / 2 : 0
            
            ///I showed 10 animations here. You can uncomment any of this and export a video to see the result.
            
            ///#1. left->right///
            //                let blackLayer = CALayer()
            //                blackLayer.frame = CGRect(x: -videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //                blackLayer.backgroundColor = UIColor.black.cgColor
            //
            //                let imageLayer = CALayer()
            //                imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //                imageLayer.contents = imgarray[image].cgImage
            //                blackLayer.addSublayer(imageLayer)
            //
            //                let animation = CABasicAnimation()
            //                animation.keyPath = "position.x"
            //                animation.fromValue = -videoTrack.naturalSize.width
            //                animation.toValue = 2 * (videoTrack.naturalSize.width)
            //                animation.duration = 3
            //                animation.beginTime = CFTimeInterval(time[image])
            //                animation.fillMode = CAMediaTimingFillMode.forwards
            //                animation.isRemovedOnCompletion = false
            //                blackLayer.add(animation, forKey: "basic")
            
            ///#2. right->left///
            //            let blackLayer = CALayer()
            //            blackLayer.frame = CGRect(x: 2 * videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //            blackLayer.backgroundColor = UIColor.black.cgColor
            //
            //            let imageLayer = CALayer()
            //            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //            imageLayer.contents = imgarray[image].cgImage
            //            blackLayer.addSublayer(imageLayer)
            //
            //            let animation = CABasicAnimation()
            //            animation.keyPath = "position.x"
            //            animation.fromValue = 2 * (videoTrack.naturalSize.width)
            //            animation.toValue = -videoTrack.naturalSize.width
            //            animation.duration = 3
            //            animation.beginTime = CFTimeInterval(time[image])
            //            animation.fillMode = kCAFillModeForwards
            //            animation.isRemovedOnCompletion = false
            //            blackLayer.add(animation, forKey: "basic")
            
            ///#3. top->bottom///
            //            let blackLayer = CALayer()
            //            blackLayer.frame = CGRect(x: 0, y: 2 * videoTrack.naturalSize.height, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //            blackLayer.backgroundColor = UIColor.black.cgColor
            //
            //            let imageLayer = CALayer()
            //            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //            imageLayer.contents = imgarray[image].cgImage
            //            blackLayer.addSublayer(imageLayer)
            //
            //            let animation = CABasicAnimation()
            //            animation.keyPath = "position.y"
            //            animation.fromValue = 2 * videoTrack.naturalSize.height
            //            animation.toValue = -videoTrack.naturalSize.height
            //            animation.duration = 3
            //            animation.beginTime = CFTimeInterval(time[image])
            //            animation.fillMode = kCAFillModeForwards
            //            animation.isRemovedOnCompletion = false
            //            blackLayer.add(animation, forKey: "basic")
            
            ///#4. bottom->top///
            //            let blackLayer = CALayer()
            //            blackLayer.frame = CGRect(x: 0, y: -videoTrack.naturalSize.height, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //            blackLayer.backgroundColor = UIColor.black.cgColor
            //
            //            let imageLayer = CALayer()
            //            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //            imageLayer.contents = imgarray[image].cgImage
            //            blackLayer.addSublayer(imageLayer)
            //
            //            let animation = CABasicAnimation()
            //            animation.keyPath = "position.y"
            //            animation.fromValue = -videoTrack.naturalSize.height
            //            animation.toValue = 2 * videoTrack.naturalSize.height
            //            animation.duration = 3
            //            animation.beginTime = CFTimeInterval(time[image])
            //            animation.fillMode = kCAFillModeForwards
            //            animation.isRemovedOnCompletion = false
            //            blackLayer.add(animation, forKey: "basic")
            
            ///#5. opacity(1->0)(left->right)///
            let blackLayer = CALayer()
            blackLayer.frame = CGRect(x: -videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            blackLayer.backgroundColor = UIColor.black.cgColor
            
            let imageLayer = CALayer()
            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            imageLayer.contents = imgarray[image].cgImage
            blackLayer.addSublayer(imageLayer)
            
            let animation = CABasicAnimation()
            animation.keyPath = "position.x"
            animation.fromValue = -videoTrack.naturalSize.width
            animation.toValue = 2 * (videoTrack.naturalSize.width)
            animation.duration = 3
            animation.beginTime = CFTimeInterval(time[image])
            animation.fillMode = CAMediaTimingFillMode.forwards
            animation.isRemovedOnCompletion = false
            blackLayer.add(animation, forKey: "basic")
            
            let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
            fadeOutAnimation.fromValue = 1
            fadeOutAnimation.toValue = 0
            fadeOutAnimation.duration = 2.5
            fadeOutAnimation.beginTime = CFTimeInterval(time[image])
            fadeOutAnimation.isRemovedOnCompletion = false
            blackLayer.add(fadeOutAnimation, forKey: "opacity")
            
            ///#6. opacity(1->0)(right->left)///
            //            let blackLayer = CALayer()
            //            blackLayer.frame = CGRect(x: 2 * videoTrack.naturalSize.width, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //            blackLayer.backgroundColor = UIColor.black.cgColor
            //
            //            let imageLayer = CALayer()
            //            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //            imageLayer.contents = imgarray[image].cgImage
            //            blackLayer.addSublayer(imageLayer)
            //
            //            let animation = CABasicAnimation()
            //            animation.keyPath = "position.x"
            //            animation.fromValue = 2 * videoTrack.naturalSize.width
            //            animation.toValue = -videoTrack.naturalSize.width
            //            animation.duration = 3
            //            animation.beginTime = CFTimeInterval(time[image])
            //            animation.fillMode = kCAFillModeForwards
            //            animation.isRemovedOnCompletion = false
            //            blackLayer.add(animation, forKey: "basic")
            //
            //            let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
            //            fadeOutAnimation.fromValue = 1
            //            fadeOutAnimation.toValue = 0
            //            fadeOutAnimation.duration = 3
            //            fadeOutAnimation.beginTime = CFTimeInterval(time[image])
            //            fadeOutAnimation.isRemovedOnCompletion = false
            //            blackLayer.add(fadeOutAnimation, forKey: "opacity")
            
            ///#7. opacity(1->0)(top->bottom)///
            //            let blackLayer = CALayer()
            //            blackLayer.frame = CGRect(x: 0, y: 2 * videoTrack.naturalSize.height, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //            blackLayer.backgroundColor = UIColor.black.cgColor
            //
            //            let imageLayer = CALayer()
            //            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //            imageLayer.contents = imgarray[image].cgImage
            //            blackLayer.addSublayer(imageLayer)
            //
            //            let animation = CABasicAnimation()
            //            animation.keyPath = "position.y"
            //            animation.fromValue = 2 * videoTrack.naturalSize.height
            //            animation.toValue = -videoTrack.naturalSize.height
            //            animation.duration = 3
            //            animation.beginTime = CFTimeInterval(time[image])
            //            animation.fillMode = kCAFillModeForwards
            //            animation.isRemovedOnCompletion = false
            //            blackLayer.add(animation, forKey: "basic")
            //
            //            let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
            //            fadeOutAnimation.fromValue = 1
            //            fadeOutAnimation.toValue = 0
            //            fadeOutAnimation.duration = 3
            //            fadeOutAnimation.beginTime = CFTimeInterval(time[image])
            //            fadeOutAnimation.isRemovedOnCompletion = false
            //            blackLayer.add(fadeOutAnimation, forKey: "opacity")
            
            ///#8. opacity(1->0)(bottom->top)///
            //            let blackLayer = CALayer()
            //            blackLayer.frame = CGRect(x: 0, y: -videoTrack.naturalSize.height, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //            blackLayer.backgroundColor = UIColor.black.cgColor
            //
            //            let imageLayer = CALayer()
            //            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //            imageLayer.contents = imgarray[image].cgImage
            //            blackLayer.addSublayer(imageLayer)
            //
            //            let animation = CABasicAnimation()
            //            animation.keyPath = "position.y"
            //            animation.fromValue = -videoTrack.naturalSize.height
            //            animation.toValue = 2 * videoTrack.naturalSize.height
            //            animation.duration = 3
            //            animation.beginTime = CFTimeInterval(time[image])
            //            animation.fillMode = kCAFillModeForwards
            //            animation.isRemovedOnCompletion = false
            //            blackLayer.add(animation, forKey: "basic")
            //
            //            let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
            //            fadeOutAnimation.fromValue = 1
            //            fadeOutAnimation.toValue = 0
            //            fadeOutAnimation.duration = 3
            //            fadeOutAnimation.beginTime = CFTimeInterval(time[image])
            //            fadeOutAnimation.isRemovedOnCompletion = false
            //            blackLayer.add(fadeOutAnimation, forKey: "opacity")
            
            ///#9. scale(small->big->small)///
            //            let blackLayer = CALayer()
            //            blackLayer.frame = CGRect(x: 0, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //            blackLayer.backgroundColor = UIColor.black.cgColor
            //            blackLayer.opacity = 0
            //
            //            let imageLayer = CALayer()
            //            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //            imageLayer.contents = imgarray[image].cgImage
            //            blackLayer.addSublayer(imageLayer)
            //
            //            let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
            //            scaleAnimation.values = [0, 1.0, 0]
            //            scaleAnimation.beginTime = CFTimeInterval(time[image])
            //            scaleAnimation.duration = 3
            //            scaleAnimation.isRemovedOnCompletion = false
            //            blackLayer.add(scaleAnimation, forKey: "transform.scale")
            //
            //            let fadeInOutAnimation = CABasicAnimation(keyPath: "opacity")
            //            fadeInOutAnimation.fromValue = 1
            //            fadeInOutAnimation.toValue = 1
            //            fadeInOutAnimation.duration = 3
            //            fadeInOutAnimation.beginTime = CFTimeInterval(time[image])
            //            fadeInOutAnimation.isRemovedOnCompletion = false
            //            blackLayer.add(fadeInOutAnimation, forKey: "opacity")
            
            ///#10. scale(big->small->big)///
            //            let blackLayer = CALayer()
            //            blackLayer.frame = CGRect(x: 0, y: 0, width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
            //            blackLayer.backgroundColor = UIColor.black.cgColor
            //            blackLayer.opacity = 0
            //
            //            let imageLayer = CALayer()
            //            imageLayer.frame = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
            //            imageLayer.contents = imgarray[image].cgImage
            //            blackLayer.addSublayer(imageLayer)
            //
            //            let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
            //            scaleAnimation.values = [1, 0, 1]
            //            scaleAnimation.beginTime = CFTimeInterval(time[image])
            //            scaleAnimation.duration = 3
            //            scaleAnimation.isRemovedOnCompletion = false
            //            blackLayer.add(scaleAnimation, forKey: "transform.scale")
            //
            //            let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
            //            fadeOutAnimation.fromValue = 1
            //            fadeOutAnimation.toValue = 1
            //            fadeOutAnimation.duration = 3
            //            fadeOutAnimation.beginTime = CFTimeInterval(time[image])
            //            fadeOutAnimation.isRemovedOnCompletion = false
            //            blackLayer.add(fadeOutAnimation, forKey: "opacity")
            
            parentlayer.addSublayer(blackLayer)
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        let layercomposition = AVMutableVideoComposition()
        layercomposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        layercomposition.renderSize = size
        layercomposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videolayer, in: parentlayer)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: composition.duration)
        let videotrack = composition.tracks(withMediaType: AVMediaType.video)[0] as AVAssetTrack
        let layerinstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videotrack)
        instruction.layerInstructions = [layerinstruction]
        layercomposition.instructions = [instruction]
        
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("temp.mp4"))
        try? FileManager.default.removeItem(at: tempURL)
        guard let assetExport = AVAssetExportSession(asset: composition, presetName:AVAssetExportPresetHighestQuality) else {return}
        assetExport.videoComposition = layercomposition
        assetExport.outputFileType = AVFileType.mp4
        assetExport.outputURL = tempURL
        assetExport.exportAsynchronously(completionHandler: {
            switch assetExport.status{
            case  AVAssetExportSession.Status.failed:
                print("failed \(String(describing: assetExport.error))")
            case AVAssetExportSession.Status.cancelled:
                print("cancelled \(String(describing: assetExport.error))")
            default:
                print("Exported")
                completion?(.success(assetExport.outputURL!))
            }
        })
    }
    
    func newoverlay(video firstAsset: AVURLAsset, withSecondVideo secondAsset: AVURLAsset,completion: MTMovieMakerCompletion? = nil) {



        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()

        // 2 - Create two video tracks
        guard let firstTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        do {
            try firstTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: firstAsset.duration),
                                           of: firstAsset.tracks(withMediaType: .video)[0],
                                           at: CMTime.zero)
        } catch {
            print("Failed to load first track")
            return
        }

        guard let secondTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                               preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { return }
        do {
            try secondTrack.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: secondAsset.duration),
                                            of: secondAsset.tracks(withMediaType: .video)[0],
                                            at: CMTime.zero)
        } catch {
            print("Failed to load second track")
            return
        }

        // 2.1
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: firstAsset.duration)

        // 2.2
        let firstInstruction = self.videoCompositionInstruction(firstTrack, asset: firstAsset)

        let secondInstruction = self.videoCompositionInstruction(secondTrack, asset: secondAsset)
        let factorWidth = firstTrack.naturalSize.width / secondTrack.naturalSize.width
        let factorHeight = firstTrack.naturalSize.height / secondTrack.naturalSize.height

        let scale = CGAffineTransform(scaleX: factorWidth, y: factorHeight)
        let move = CGAffineTransform(translationX: 0, y: 0)
        
        secondInstruction.setTransform(scale.concatenating(move), at: CMTime.zero)
        //secondInstruction.setOpacityRamp(fromStartOpacity: 0.5, toEndOpacity: 0.0, timeRange: CMTimeRangeMake(start: .zero, duration: secondAsset.duration))
        // 2.3
        mainInstruction.layerInstructions = [ secondInstruction,firstInstruction]
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)

//        let width = max(firstTrack.naturalSize.width, secondTrack.naturalSize.width)
//        let height = max(firstTrack.naturalSize.height, secondTrack.naturalSize.height)

        mainComposition.renderSize = CGSize(width: firstTrack.naturalSize.width, height: firstTrack.naturalSize.height)

        mainInstruction.backgroundColor = UIColor.red.cgColor


        // 4 - Get path
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: Date())
        let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")

        // Check exists and remove old file
        try? FileManager.default.removeItem(at: url)


        
        // 5 - Create Exporter
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = url
        exporter.outputFileType = AVFileType.mov
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = mainComposition


        // 6 - Perform the Export
        exporter.exportAsynchronously {
            switch exporter.status{
            case  AVAssetExportSession.Status.failed:
                print("failed \(String(describing: exporter.error))")
            case AVAssetExportSession.Status.cancelled:
                print("cancelled \(String(describing: exporter.error))")
            default:
                print("Exported")
                completion?(.success(exporter.outputURL!))
            }
        }
    }
    
    func videoCompositionInstruction(_ track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]

        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform)

        var scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.width
        if assetInfo.isPortrait {
            scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor), at: CMTime.zero)
        } else {
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            var concat = assetTrack.preferredTransform.concatenating(scaleFactor)
                .concatenating(CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.width / 2))
            if assetInfo.orientation == .down {
                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                let windowBounds = UIScreen.main.bounds
                let yFix = assetTrack.naturalSize.height + windowBounds.height
                let centerFix = CGAffineTransform(translationX: assetTrack.naturalSize.width, y: yFix)
                concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
            }
            //instruction.setTransform(concat, at: CMTime.zero)
        }

        return instruction
    }

    func orientationFromTransform(_ transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    func removeBackgroundFromVideo(asset:AVAsset) -> AVAsset? {
        guard let context = mtiContext, let videoSize = asset.tracks.first?.naturalSize else {
            return nil
        }
        
        
        let chromaKeyBlendFilter = MTIChromaKeyBlendFilter()
        
        let color = MTIColor(red: 0.998, green: 0.0, blue: 0.996, alpha: 1)
        //let backgroundColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        let backgroundColor = MTIColor(red: 0.0, green: 0.0, blue: 0, alpha: 0)
        chromaKeyBlendFilter.color = color
        chromaKeyBlendFilter.smoothing = 0.001
        chromaKeyBlendFilter.thresholdSensitivity = 0.4//0.475
        chromaKeyBlendFilter.inputBackgroundImage = MTIImage(color: backgroundColor, sRGB: false, size: videoSize)
        let composition = MTIVideoComposition(asset: asset, context: context, queue: DispatchQueue.main, filter: { request in
            
            guard let sourceImage = request.anySourceImage else {
                return MTIImage(color: backgroundColor, sRGB: false, size: videoSize)
            }
            return FilterGraph.makeImage(builder: { output in
                sourceImage => chromaKeyBlendFilter.inputPorts.inputImage
                chromaKeyBlendFilter => output
            })!
        })
        return composition.asset
    }
    
    func addOverlay(asset:AVAsset,overlayAsset:AVAsset,                            audioURL: URL? = nil,rewindOverlay:Bool = true,
completion: @escaping MTMovieMakerCompletion)throws -> Void {
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("temp.mp4"))
        try? FileManager.default.removeItem(at: tempURL)

        let track =  asset.tracks(withMediaType: AVMediaType.video)
        let videoTrack:AVAssetTrack = track[0] as AVAssetTrack
        
        let outputSize = videoTrack.naturalSize
        
        if FileManager.default.fileExists(atPath: tempURL.path) {
            try FileManager.default.removeItem(at: tempURL)
        }
        
        writer = try? AVAssetWriter(outputURL: tempURL, fileType: .mp4)
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
        
        

        self.writer?.startSession(atSourceTime: .zero)
        writerInput.requestMediaDataWhenReady(on: self.writingQueue) {
            
            var reader:AVAssetReader!
            do {
                reader = try AVAssetReader(asset: asset)
            } catch  {
                print(error.localizedDescription)
            }


            let videoTrack = asset.tracks(withMediaType: AVMediaType.video)[0]

            // read video frames as BGRA
            let trackReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])

            reader.add(trackReaderOutput)
            
            let reader2 = try! AVAssetReader(asset: overlayAsset)

            let videoTrack2 = overlayAsset.tracks(withMediaType: AVMediaType.video)[0]

            // read video frames as BGRA
            let trackReaderOutput2 = AVAssetReaderTrackOutput(track: videoTrack2, outputSettings:[String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
            trackReaderOutput2.supportsRandomAccess = true;

            reader2.add(trackReaderOutput2)
            


            let chromaKeyBlendFilter = MTIChromaKeyBlendFilter()
            let overlayBlendFilter = MTIBlendFilter(blendMode: .overlay)
            
            var sampleOverlayMtiImages = [MTIImage]()
            var overlayImageIndex = 0
            
            reader2.startReading()
            
            while let sampleBuffer2 = trackReaderOutput2.copyNextSampleBuffer(){
                if let imageBuffer2:CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer2) {
                    let overlayMtiImage = MTIImage(cvPixelBuffer: imageBuffer2, alphaType: .alphaIsOne)
                    sampleOverlayMtiImages.append(overlayMtiImage)

                }
                    
            }
            reader2.cancelReading()

            reader.startReading()
            
            while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
                
                let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                
                print("sample at time BG \(presentationTime) sec \(CMTimeGetSeconds(presentationTime)) duration \(CMTimeGetSeconds(presentationTime))")
                
                if let imageBuffer:CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                    
                    let bgMtiImage = MTIImage(cvPixelBuffer: imageBuffer, alphaType: .alphaIsOne)
                    
                    let overlayMtiImage = sampleOverlayMtiImages[overlayImageIndex]
                    let backgroundColor = MTIColor(red: 0.0, green: 0.0, blue: 0, alpha: 0)
                    chromaKeyBlendFilter.color = MTIColor(red: 1.0, green: 0.0, blue: 0, alpha: 0.3)
                    chromaKeyBlendFilter.inputImage = overlayMtiImage
                    chromaKeyBlendFilter.smoothing = 0.001
                    chromaKeyBlendFilter.thresholdSensitivity = 0.4//0.475
                    chromaKeyBlendFilter.inputBackgroundImage = MTIImage(color: backgroundColor, sRGB: false, size: overlayMtiImage.size)
                     
                    overlayBlendFilter.inputImage = chromaKeyBlendFilter.outputImage?.resized(to: bgMtiImage.size)
                    overlayBlendFilter.inputBackgroundImage = bgMtiImage
                    

                    
                    
                    var pixelBuffer: CVPixelBuffer?
                    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
                    
                    if let buffer = pixelBuffer,let frame = overlayBlendFilter.outputImage {
                        try? BCLTransition.context?.render(frame, to: buffer)
                        
                        while pixelBufferAdaptor.assetWriterInput.isReadyForMoreMediaData == false {
                            print("Thread sleeping to get ready to append pixel buffer")
                            Thread.sleep(forTimeInterval: 0.1)
                        }
                        pixelBufferAdaptor.append(buffer, withPresentationTime: presentationTime)
                        
                        
                    }
                    
                    overlayImageIndex += 1
                    
                    if overlayImageIndex == sampleOverlayMtiImages.count, rewindOverlay {
                        overlayImageIndex = 0
                    }
                    
                }
            }
            
            writerInput.markAsFinished()
            self.writer?.finishWriting {
                if let audioURL = audioURL, self.writer?.error == nil {
                    do {
                        let audioAsset = AVAsset(url: audioURL)
                        let videoAsset = AVAsset(url: tempURL)
                        try self.mixAudio(audioAsset, video: videoAsset, completion: completion)
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    DispatchQueue.main.async {
                        if let error = self.writer?.error {
                            completion(.failure(error))
                        } else {
                            completion(.success(tempURL))
                        }
                    }
                }
            }
        }
        
    }
}
