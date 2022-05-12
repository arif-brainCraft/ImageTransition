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
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var exportButton : UIBarButtonItem!
    var movieMaker:CombineTransitionMovieMaker?
    var fileUrl:URL?
    
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
        let allImages = loadImages()
        
        let effects: [MTTransition.Effect] = [.burn,.wipeUp,.wipeLeft,.bowTieHorizontal,.crossHatch]
        var blendEffects = [Int]()
        blendEffects.append(2)
        blendEffects.append(4)

        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let path = documentDirectory.appendingPathComponent("CreateVideoFromImages.mp4").path
        let url = URL(fileURLWithPath: path)
        
        movieMaker = CombineTransitionMovieMaker(outputURL: url)
        do {
            
            
            try movieMaker?.createCombinedTransitionVideo(with: allImages, effects: effects, blendEffects: blendEffects, frameDuration: 2.5, transitionDuration: 1, audioURL: nil, completion: {[weak self] result in
                guard let self = self else {return}
                switch result {
                case .success(let url):
                    print(url)
                    let asset = AVURLAsset(url: url)
                    asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
                        if let url = Bundle.main.url(forResource: "Abstract", withExtension: "mp4") {
                            var overlayAsset = AVURLAsset(url: url)
                            overlayAsset.loadValuesAsynchronously(forKeys: ["tracks"]) {
                                do {
                                    try self.movieMaker?.addOverlay(asset: asset, overlayAsset: overlayAsset, completion: {[weak self] result in
                                        guard let self = self else {return}
                                        switch result {
                                        case .success(let outputUrl):
                                            self.playVideo(url: outputUrl)

                                            break

                                        case .failure(let error):
                                            break
                                        }
                                    })
                                } catch {
                                }
                            }
                            
                            
                        }
                    }
                    

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
    
    func loadImages() -> [UIImage] {
        var images = [UIImage]()
        for i in 5...8 {
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
    @IBAction func restartButtonPressed(_ sender: Any) {
        self.player.seek(to: .zero)
        self.player.play()
    }
    

}
