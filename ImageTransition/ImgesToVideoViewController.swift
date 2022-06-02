//
//  ImgesToVideoViewController.swift
//  ImageTransition
//
//  Created by BCL Device7 on 27/4/22.
//

import UIKit
import AVFoundation
import Photos
import MTTransitions

class ImgesToVideoViewController: UIViewController {
    
    @IBOutlet var videoView: UIView!
    @IBOutlet var ratioCollectionView:UICollectionView!
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var exportButton : UIBarButtonItem!
    var movieMaker:CombineTransitionMovieMaker?
    var fileUrl:URL?
    let aspectRatioes = [CGSize(width: 1, height: 1), CGSize(width: 4, height: 5),CGSize(width: 9, height: 16),CGSize(width: 16, height: 9)]
    var selectedRatio:CGSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Image To Video"
        selectedRatio = aspectRatioes.first!
        exportButton = UIBarButtonItem(title: "Export", style: .plain, target: self, action: #selector(exportButtonPressed))
        self.navigationItem.rightBarButtonItem = exportButton
        resizeVideView(rect: getResizedRectAsRatio(aspectRatio: selectedRatio))
        setUpSubviews()
        createVideo()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
    }
    
    func setUpSubviews() -> Void {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.pixelBufferAttributes = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]
        videoView.layer.addSublayer(playerLayer)
        
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        Thread.sleep(forTimeInterval: 2)
        player.seek(to: .zero)
    }
    
    func createVideo() -> Void {
        
        let effects: [BCLTransition.Effect] = [.doomScreenTransition]
        
        var blendEffects = [Int]()
        
        let allImages = loadImages(count: effects.count + 1 - blendEffects.count )
        

        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let path = documentDirectory.appendingPathComponent("CreateVideoFromImages.mp4").path
        let url = URL(fileURLWithPath: path)
        
        movieMaker = CombineTransitionMovieMaker(outputURL: url)
        do {
            
            let duration = Float(effects.count) * 2
            
            try movieMaker?.createCombinedTransitionVideo(with: allImages, effects: effects, blendEffects: blendEffects, frameDuration: TimeInterval(Float(allImages.count) * 2.5), transitionDuration: 4, audioURL: nil, completion: {[weak self] result in
                guard let self = self else {return}
                switch result {
                case .success(let url):
                    print(url)
                    self.playVideo(url: url)
                    
                    //                    let asset = AVURLAsset(url: url)
                    //                    asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
                    //                        if let url = Bundle.main.url(forResource: "Abstract", withExtension: "mp4") {
                    //                            var overlayAsset = AVURLAsset(url: url)
                    //                            overlayAsset.loadValuesAsynchronously(forKeys: ["tracks"]) {
                    //                                do {
                    //                                    try self.movieMaker?.addOverlay(asset: asset, overlayAsset: overlayAsset, completion: {[weak self] result in
                    //                                        guard let self = self else {return}
                    //                                        switch result {
                    //                                        case .success(let outputUrl):
                    //                                            self.playVideo(url: outputUrl)
                    //
                    //                                            break
                    //
                    //                                        case .failure(let error):
                    //                                            break
                    //                                        }
                    //                                    })
                    //                                } catch {
                    //                                }
                    //                            }
                    //
                    //
                    //                        }
                    //                    }
                    
                    
                    //                    self.movieMaker?.exportVideoWithAnimation(asset: asset, completion: {[weak self] result in
                    //                        guard let self = self else {return}
                    //                        switch result {
                    //                        case .success(let url):
                    //                            self.playVideo(url: url)
                    //
                    //                            break
                    //
                    //                        case .failure(let error):
                    //                            break
                    //                        }
                    //                    })
                    
                    break
                    
                case .failure(let error):
                    break
                }
            })
            
        } catch  {
            
        }
        
        
    }
    
    func playVideo(url:URL) -> Void {
        self.fileUrl = url
        let playerItem = AVPlayerItem(url: url)
        self.player.replaceCurrentItem(with: playerItem)
        self.player.play()
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem)
        
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(self.playerDidFinishPlaying),
                         name: .AVPlayerItemDidPlayToEndTime,
                         object: self.player.currentItem)
    }
    
    func loadImages(count:Int) -> [UIImage] {
        var images = [UIImage]()
        for _ in 0..<count {
            let i = Int.random(in: 0..<9)
            if let url = Bundle.main.url(forResource: String(i), withExtension: "jpg") {
                if let image = UIImage(contentsOfFile: url.path) {
                    images.append(image)
                }
            }
            
        }
        return images
    }
    
    @objc func exportButtonPressed() -> Void {
        guard let fileUrl = fileUrl else {
            return
        }
        let asset = AVAsset(url: fileUrl)
        let tracksKey = #keyPath(AVAsset.tracks)
        asset.loadValuesAsynchronously(forKeys: [tracksKey]){
            DispatchQueue.main.async {
                let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                
                let path = documentDirectory.appendingPathComponent("exported.mp4").path
                let url = URL(fileURLWithPath: path)
                try? FileManager.default.removeItem(at: url)
                
                if let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality){
                    
                    exporter.outputFileType = .mp4
                    exporter.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
                    exporter.videoComposition = self.getScaledVideoComposition(aspectRatio: self.selectedRatio, asset: asset)
                    exporter.outputURL = url
                    
                    exporter.exportAsynchronously {
                        switch exporter.status {
                        case .completed:
                            self.exportToPhotoLibrary(url: exporter.outputURL!)
                            break
                        case .failed:
                            print(exporter.error?.localizedDescription)
                            break
                        default:
                            break
                        }
                        
                    }
                }
            }
        }
        
        
    }
    
    func getScaledVideoComposition(aspectRatio:CGSize,asset:AVAsset) -> AVMutableVideoComposition? {
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else{return nil}

        
        let canvasSize = CGSize(width: 512, height: 910)
        let composition = AVMutableVideoComposition(propertiesOf: asset)
        composition.renderSize = canvasSize

        //composition.frameDuration = CMTime(value: 1, timescale: CMTimeScale(NSEC_PER_SEC))
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
        
        let layerInstruction : AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let layerFrame = CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height)
        let bSize = videoTrack.naturalSize
        let transform =  CGAffineTransform(scaleX: layerFrame.width/videoTrack.naturalSize.width , y: layerFrame.height/videoTrack.naturalSize.height)
        
        let size = __CGSizeApplyAffineTransform(videoTrack.naturalSize, transform)

        let Y = (canvasSize.height - bSize.height)/2
        let X = (canvasSize.width - bSize.width)/2

        //transform = transform.concatenating(CGAffineTransform(translationX: X, y: Y))

        let point = __CGPointApplyAffineTransform(CGPoint(x: 0, y: 0), transform)
        layerInstruction.setTransform(transform, at: .zero)
        
        addBackground(image: UIImage(color: .red)!, composition: composition, origin: CGPoint(x: X, y: Y), layerSize: bSize, parentLayerSize: canvasSize)


        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]
        return composition
    }
    
    func addBackground(image:UIImage,composition:AVMutableVideoComposition,origin:CGPoint,layerSize:CGSize,parentLayerSize:CGSize) -> Void {
                
        let parentSize = parentLayerSize

        // 2 - set up the parent layer
        let parentLayer = CALayer()
        let videoLayer = AVPlayerLayer()
        parentLayer.backgroundColor = UIColor.red.cgColor
        parentLayer.frame = CGRect(x: 0, y: 0, width: parentSize.width, height: parentSize.height)
        
        videoLayer.frame = CGRect(x: origin.x, y: origin.y, width: layerSize.width, height: layerSize.height)
//        videoLayer.videoGravity = .resizeAspect
        videoLayer.backgroundColor = UIColor.blue.cgColor
        
        
        //parentLayer.addSublayer(overlayLayer)
        parentLayer.addSublayer(videoLayer)
        parentLayer.isGeometryFlipped = true
        //parentLayer.addSublayer(overlayLayer2)
        
        // 3 - apply magic
        composition.animationTool = AVVideoCompositionCoreAnimationTool(
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
                            self.present(alert, animated: true, completion: nil)
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
    
    func resizeVideView(rect:CGRect) -> Void {
        
        let maxBounds = self.videoView.superview!.bounds
        
        var rectangle = rect
        var size = rect.size
        
        if size.width > size.height {
            size.width = videoView.superview!.bounds.width
        }else{
            size.height = videoView.superview!.bounds.height
        }
        
        let tempOrigin = CGPoint(x: maxBounds.midX - size.width/2, y: maxBounds.midY - size.height/2)

        rectangle.size = size
        rectangle.origin = tempOrigin
        videoView.frame = rectangle
        
    }
    
    func resizePlayerLayer(rect:CGRect) -> Void {
        let maxBounds = videoView.bounds
        
        let tempOrigin = CGPoint(x: maxBounds.midX - rect.width/2, y: maxBounds.midY - rect.height/2)
        
        let rectangle = CGRect(x: tempOrigin.x, y: tempOrigin.y, width:rect.width , height: rect.height)
        if let asset = player.currentItem?.asset{
            
            playerLayer.frame = AVMakeRect(aspectRatio: self.getAspectRatio(asset: asset), insideRect: rectangle)
            playerLayer.removeAllAnimations()
            
            
        }
        
        
    }
    
    func getResizedRectAsRatio(aspectRatio:CGSize) -> CGRect {
        
        let maxBounds = videoView.superview!.bounds
        let maxSize = CGSize(width: maxBounds.width, height: maxBounds.width)
        let minSize = CGSize(width: maxSize.width/2, height: maxSize.height/2)
        
        
        var width = maxSize.width * aspectRatio.width
        var height = maxSize.height * aspectRatio.height
        var diffPercent:CGFloat = 0.0
        
        
        if width > height {
            if width > maxBounds.width {
                let diff = width - maxBounds.width
                
                diffPercent =  diff * 100.0 / width
                width = width - diff
                
                height = height - (height * diffPercent / 100)
                
                if height < minSize.height {
                    let diff = minSize.height - height
                    
                    diffPercent =  diff * 100.0 / height
                    height = height + diff
                    
                    width = width + (width * diffPercent / 100)
                }
            }
        }else if height > width{
            if height > maxBounds.height {
                let diff = height - maxBounds.height
                
                diffPercent =  diff * 100.0 / height
                height = height - diff
                width = width - (width * diffPercent / 100)
                
                if width < minSize.width {
                    let diff = minSize.width - width
                    
                    diffPercent =  diff * 100.0 / width
                    width = width + diff
                    
                    height = height + (height * diffPercent / 100)
                }
                
            }
        }
        
        
        let tempOrigin = CGPoint(x: maxBounds.midX - width/2, y: maxBounds.midY - height/2)
        
        let rect = CGRect(x: tempOrigin.x, y: tempOrigin.y, width:width , height: height)
        print("origin: \(tempOrigin) width: \(width) height \(height) ratio: \(width/height)")
        
        return rect
    }
    
    @IBAction func restartButtonPressed(_ sender: Any) {
        self.player.seek(to: .zero)
        self.player.play()
    }
    
    @IBAction func reCreateVideo(_ sender: Any) {
        self.createVideo()
    }
    
    @IBAction func aspectFitButtonPressed(_ sender: Any) {
        playerLayer.videoGravity = .resizeAspect
        
        let rect = getResizedRectAsRatio(aspectRatio: selectedRatio)
        
        self.resizeVideView(rect: rect)
        self.resizePlayerLayer(rect: rect)
        self.videoView.superview?.layoutIfNeeded()
        
        
    }
    
    @IBAction func aspectFillButtonPressed(_ sender: Any) {
        playerLayer.videoGravity = .resizeAspectFill
        
        let rect = getResizedRectAsRatio(aspectRatio: selectedRatio)
        
        self.resizeVideView(rect: rect)
        self.resizePlayerLayer(rect: rect)
        self.videoView.superview?.layoutIfNeeded()
    }
    
}


extension ImgesToVideoViewController:UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let space = 5
        let collectionSize = collectionView.frame.size
        return CGSize(width: collectionSize.width / CGFloat(aspectRatioes.count) - CGFloat(space * (aspectRatioes.count - 1) ), height: collectionSize.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return aspectRatioes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AspectRatioCollectionCell", for: indexPath) as! AspectRatioCollectionCell
        
        let width = String(format: "%d", Int(aspectRatioes[indexPath.item].width))
        let height = String(format: "%d", Int(aspectRatioes[indexPath.item].height))
        
        cell.aspectLabel.text = "\(width):\(height)"
        
        cell.contentView.layer.cornerRadius = 5
        cell.contentView.layer.borderColor = UIColor.blue.cgColor
        cell.contentView.layer.borderWidth = 1
        cell.contentView.layer.masksToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        //        if let cell = collectionView.cellForItem(at: indexPath) {
        //            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
        //                cell.backgroundColor = UIColor.lightGray
        //            }, completion: { _ in
        //                cell.backgroundColor = UIColor.white
        //            })
        //        }
        selectedRatio = aspectRatioes[indexPath.item]
        playerLayer.videoGravity = .resizeAspect
        
        let rect = getResizedRectAsRatio(aspectRatio: selectedRatio)
        
        self.resizeVideView(rect: rect)
        self.resizePlayerLayer(rect: rect)
        self.videoView.superview?.layoutIfNeeded()
        
    }
    
    
    
}
