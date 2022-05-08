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
        
        videoView.layer.addSublayer(playerLayer)
        
    }
    
    func createVideo() -> Void {
        let allImages = loadImages()
        
        let effects: [MTTransition.Effect] = [.crossZoom,
            .crossWarp]
        
        let secondEffects: [MTTransition.Effect] = [
            .angular, .bowTieHorizontal, .burn,
            .butterflyWaveScrawler, .none]
        
        let path = NSTemporaryDirectory().appending("CreateVideoFromImages.mp4")
        let url = URL(fileURLWithPath: path)
        
        movieMaker = CombineTransitionMovieMaker(outputURL: url)
        do {
            
            try movieMaker?.createCombinedTransitionVideo(with: allImages, effects: effects, frameDuration: 2.5, transitionDuration: 1, audioURL: nil, completion: {[weak self] result in
                guard let self = self else {return}
                switch result {
                case .success(let url):
                    self.fileUrl = url
                    let playerItem = AVPlayerItem(url: url)
                    self.player.replaceCurrentItem(with: playerItem)
                    self.player.play()
                    break
                    
                case .failure(let error):
                    break
                }
            })
            
            /*try movieMaker?.createVideo(with: allImages, effects: effects, completion: {[weak self] result in
                guard let self = self else {return}
                switch result {
                case .success(let url):
                    self.fileUrl = url
                    let playerItem = AVPlayerItem(url: url)
                    self.player.replaceCurrentItem(with: playerItem)
                    self.player.play()
                    break
                    
                case .failure(let error):
                    break
                }
            })*/
        } catch  {
            
        }
        
        
    }
    
    func loadImages() -> [UIImage] {
        var images = [UIImage]()
        for i in 1...3 {
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
