//
//  VideoCompositionManager.swift
//  ImageTransition
//
//  Created by BCL Device7 on 14/6/22.
//

import UIKit
import AVFoundation
import Photos

class VideoCompositionManager: NSObject {

    func getNaturalSize(asset:AVAsset) -> CGSize {
        
        let orientation = getOrientation(asset: asset)
        if let naturalSize = asset.tracks(withMediaType: .video).first?.naturalSize {
            if orientation.isPortrait {
                return CGSize(width:naturalSize.height , height: naturalSize.width)
            }else{
                return naturalSize
            }
        }
        return CGSize(width: 0, height: 0)
    }
    
    func getOrientation (asset:AVAsset) -> (isPortrait:Bool,orientation:UIImage.Orientation) {
        
        var isPortrait = false
        var orientation:UIImage.Orientation = .up
        
        let transform = asset.preferredTransform
        
        if(transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0) {
            orientation = .right
            isPortrait = true
        }
        
        if(transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0)  {
            orientation =  .left
            isPortrait = true
        }
        if(transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0)   {
            orientation =  .up
        }
        if(transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0) {
            orientation = .down
        }
        return (isPortrait:isPortrait,orientation:orientation)
    }
    
    func getScaledVideoComposition(composition:AVMutableComposition,canvasSize:CGSize,assets:[AVAsset],addBackground:Bool = false,aspectFit:Bool = true) -> AVMutableVideoComposition? {
                
        var instructions = [AVMutableVideoCompositionInstruction]()
        var duration:CMTime = .zero
        var highestFrameRate = 0
        var layerRects = [CGRect]()
        var timeRanges = [Float64]()
        let parentVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        var parentAudioTrack:AVMutableCompositionTrack?

        for asset in assets {
            
            if let videoTrack = asset.tracks(withMediaType: .video).first{
                
                let layerInstruction : AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)

                
                
                
                let naturalSize = videoTrack.naturalSize
                var newsize = AVMakeRect(aspectRatio: naturalSize, insideRect: CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height))
                
                if aspectFit == false{
                    newsize = CGRect(x: newsize.minX, y: newsize.minY, width: canvasSize.width, height: canvasSize.height)
                }
                
                
                var finalTransform = videoTrack.preferredTransform.scaledBy(x:newsize.width/naturalSize.width, y: newsize.height/naturalSize.height)

                //let size = __CGSizeApplyAffineTransform(naturalSize, transform)
                let size1 = __CGSizeApplyAffineTransform(naturalSize, finalTransform)
                let point = __CGPointApplyAffineTransform(.zero, videoTrack.preferredTransform)
                
                if size1.width < 0 {
                    finalTransform = videoTrack.preferredTransform.scaledBy(x:newsize.width/naturalSize.width, y: newsize.height/naturalSize.height)
                    finalTransform = finalTransform.scaledBy(x: 1, y: -1)
                    let size = __CGSizeApplyAffineTransform(naturalSize, finalTransform)
                    let point = __CGPointApplyAffineTransform(CGPoint(x: 0, y: 0), finalTransform)

                    finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: -point.x + (canvasSize.width/2 - size.width/2), y: (canvasSize.height/2 - size.height/2)))
                }else{
                    finalTransform = finalTransform.concatenating(CGAffineTransform(translationX: -point.x + (canvasSize.width/2 - size1.width/2), y: (canvasSize.height/2 - size1.height/2)))
                }
                
                let size2 = __CGSizeApplyAffineTransform(naturalSize, finalTransform)
                let point2 = __CGPointApplyAffineTransform(CGPoint(x: 0, y: 0), finalTransform)
                layerRects.append(CGRect(x: point2.x, y: point2.y, width: size2.width, height: size2.height))
                
                print("scaled video size \(size2) \(point2)")
                
                layerInstruction.setTransform(finalTransform, at: duration)

                let currentFrameRate = Int(roundf((videoTrack.nominalFrameRate)))
                highestFrameRate = (currentFrameRate > highestFrameRate) ? currentFrameRate : highestFrameRate
                
                let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
                try? parentVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: duration)
                
                if let audioTrack = asset.tracks(withMediaType: .audio).first {
                    if parentAudioTrack == nil{
                        parentAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                    }
                    try? parentAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: duration)
                }
                


                
                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = CMTimeRangeMake(start: duration, duration: asset.duration)
                timeRanges.append(CMTimeGetSeconds(asset.duration))
                instruction.layerInstructions = [layerInstruction]
                instructions.append(instruction)
                
                duration = CMTimeAdd(duration, asset.duration)
            }
        }
        
        let videoComposition = AVMutableVideoComposition()
        
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(highestFrameRate))
        videoComposition.renderSize = canvasSize
        videoComposition.instructions = instructions
        
        if addBackground {
            self.addBackground(image: UIImage(color: .red)!, videoComposition: videoComposition,layerRects: layerRects, layerRanges: timeRanges, parentLayerSize: canvasSize)
        }

        
        return videoComposition
    }
    
    func addBackground(image:UIImage,videoComposition:AVMutableVideoComposition,layerRects:[CGRect],layerRanges:[Float64],parentLayerSize:CGSize) -> Void {
        

        
        let parentSize = parentLayerSize

        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.contents = image.cgImage
        parentLayer.frame = CGRect(x: 0, y: 0, width: parentSize.width, height: parentSize.height)
        
        videoLayer.frame = layerRects.first!
        //videoLayer.videoGravity = .resize
        videoLayer.backgroundColor = UIColor.blue.cgColor
        print("scaled export size  parent: \(parentSize) layer: \(videoLayer.frame)")

//        let duration = 2.0
        
//        for i  in 0..<layerRects.count - 1 {
//            let animation = CABasicAnimation()
//            animation.keyPath = "frame.size"
//            animation.fromValue = NSValue(cgSize: videoLayer.frame.size)
//            animation.toValue = NSValue(cgSize: layerRects[i + 1].size)
//            animation.duration = duration
//            animation.beginTime = layerRanges[i] - duration
//            //currentLayerTime + Double(layerRanges[i] - 1)
//            //animation.fillMode = CAMediaTimingFillMode
//            animation.isRemovedOnCompletion = false
//            videoLayer.add(animation, forKey: "frame.size")
//            //videoLayer.frame = layerRects[i + 1]
//        }
        
        parentLayer.addSublayer(videoLayer)
        parentLayer.isGeometryFlipped = true
        
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer)
        
    }
    
    func exportToPhotoLibrary(url:URL) -> Void {
        PHPhotoLibrary.requestAuthorization { auth in
            switch auth {
            case .authorized:
                PHPhotoLibrary.shared().performChanges {
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .video, fileURL: url, options: options)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if success && error == nil {
                            let alert = UIAlertController(title: "Video Saved To Camera Roll", message: nil, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                                
                            }))
                            print("Video Saved To Camera Roll")
                            //self.present(alert, animated: true, completion: nil)
                        }
                    }
                }
                
                break;
            default:
                print("PhotoLibrary not authorized")
                
                break;
            }
        }
    }
    

    func getAspectRatio(asset:AVAsset)->CGSize{
        
        let videoTrack = asset.tracks(withMediaType: .video).first!
        let naturalSize = videoTrack.naturalSize
        let transform = videoTrack.preferredTransform
        return naturalSize.applying(transform)
        
    }
    
}
