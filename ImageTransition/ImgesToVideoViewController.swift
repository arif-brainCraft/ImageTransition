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
    let aspectRatioes = [CGSize(width: 1, height: 1), CGSize(width: 1, height: 2),CGSize(width: 2, height: 1),CGSize(width: 2, height: 3),CGSize(width: 3, height: 4),CGSize(width: 4, height: 3)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Image To Video"
        
        exportButton = UIBarButtonItem(title: "Export", style: .plain, target: self, action: #selector(exportButtonPressed))
        self.navigationItem.rightBarButtonItem = exportButton
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
        
        let effects: [BCLTransition.Effect] = [.waterDrop,.randomAngularDreamy,.dreamyWindowSlice,.randomDownSwipe]
        let allImages = loadImages(count: effects.count + 1)

        var blendEffects = [Int]()


        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let path = documentDirectory.appendingPathComponent("CreateVideoFromImages.mp4").path
        let url = URL(fileURLWithPath: path)
        
        movieMaker = CombineTransitionMovieMaker(outputURL: url)
        do {
            
            let duration = Float(effects.count) * 2
            
            try movieMaker?.createCombinedTransitionVideo(with: allImages, effects: effects, blendEffects: blendEffects, frameDuration: TimeInterval(duration + Float(1)), transitionDuration: 4, audioURL: nil, completion: {[weak self] result in
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
        PHPhotoLibrary.requestAuthorization{ auth in
            switch auth {
            case .authorized:
                PHPhotoLibrary.shared().performChanges {
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .video, fileURL: fileUrl, options: options)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if success {
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
    
    @IBAction func restartButtonPressed(_ sender: Any) {
        self.player.seek(to: .zero)
        self.player.play()
    }
    
    @IBAction func reCreateVideo(_ sender: Any) {
        self.createVideo()
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
        
        
        if let asset = player.currentItem?.asset{
            let maxBounds = videoView.bounds
            let minSize = CGSize(width: maxBounds.width - 100, height: maxBounds.height - 100)

            let aspect = aspectRatioes[indexPath.item]
            
            var width = maxBounds.width * aspect.width
            var height = maxBounds.height * aspect.height
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
            
            playerLayer.frame = AVMakeRect(aspectRatio: self.getAspectRatio(asset: asset), insideRect: rect)
            videoView.layoutSubviews()
        }
        
    }
    
    

}
