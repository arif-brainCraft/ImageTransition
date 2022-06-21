//
//  ImgesToVideoViewController.swift
//  ImageTransition
//
//  Created by BCL Device7 on 27/4/22.
//

import UIKit
import AVFoundation
import MTTransitions

class ImgesToVideoViewController: UIViewController {
    
    @IBOutlet var videoView: UIView!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var fillButton: UIButton!
    @IBOutlet var fitButton: UIButton!

    @IBOutlet var ratioCollectionView:UICollectionView!
    private var player: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var exportButton : UIBarButtonItem!
    var movieMaker:CombineTransitionMovieMaker?
    let videoCompositionManager = VideoCompositionManager()
    let slideShowTemplate = SlideShowTemplate()
    var fileUrl:URL?
    let aspectRatioes = [CGSize(width: 1, height: 1), CGSize(width: 4, height: 5),CGSize(width: 9, height: 16),CGSize(width: 16, height: 9)]
    var selectedRatio:CGSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Image To Video"
        selectedRatio = aspectRatioes.first!
        exportButton = UIBarButtonItem(title: "Export", style: .plain, target: self, action: #selector(exportButtonPressed))
        self.navigationItem.rightBarButtonItem = exportButton
        
        self.fitButton.backgroundColor = .lightGray
        resizeVideView(rect: getResizedRectAsRatio(aspectRatio: selectedRatio,rect: self.videoView.superview!.bounds))
        setUpSubviews()
        //createVideo()
        slideShowTemplate.createVideo(allImages: loadImages(count: 4)) { [weak self] result in
            guard let self = self else {return}
            switch result {
            case .success(let url):
                self.fileUrl = url
                self.playVideo(url: url)
            case .failure(_): break

            }
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
    }
    
    func setUpSubviews() -> Void {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        //playerLayer.videoGravity = .resizeAspect
        playerLayer.pixelBufferAttributes = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]
        videoView.layer.addSublayer(playerLayer)
        
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        Thread.sleep(forTimeInterval: 2)
        player.seek(to: .zero)
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if sender.tag == 0 {
            self.player.pause()
            sender.setTitle("Play", for: .normal)
            sender.tag = 1
        }else{
            self.player.play()
            sender.tag = 0
            sender.setTitle("Pause", for: .normal)
        }
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        guard let currentItem = self.player.currentItem else {
            return
        }
        if self.player.timeControlStatus == .playing {
            self.player.pause()
            playButton.setTitle("Play", for: .normal)
            playButton.tag = 1
        }
        
        let totalDuration = CMTimeGetSeconds(currentItem.duration)
        let second = totalDuration * Float64(sender.value)
        let seektime = CMTime(seconds: second, preferredTimescale: currentItem.duration.timescale)
        print("slider value changing \(seektime)")

        self.player.seek(to: CMTime(seconds: second, preferredTimescale: currentItem.duration.timescale))
    }
    
    func createVideo() -> Void {
        
        let effects: [BCLTransition.Effect] = [.whiteMinimalBgFilter,.burn]
        
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
                    self.fileUrl = url
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
        let composition = AVMutableComposition()

//        let assets = loadAssetsToMerge()
//
//        let canvasSize = self.videoView.frame.size
//
//        guard let videoComposition = videoCompositionManager.getScaledVideoComposition(composition: composition, canvasSize: canvasSize, assets: assets) else {return}
        
        let asset = AVAsset(url: url)
        
        let playerItem = AVPlayerItem(asset: asset)
        //playerItem.videoComposition = videoComposition
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
    
    func loadAssetsToMerge() -> [AVAsset] {
        
        guard let fileUrl = fileUrl else {
            return [AVAsset]()
        }

        let asset = AVAsset(url: fileUrl)
        
        var assets = [asset]
        
        if let url = Bundle.main.url(forResource: "sixthClip", withExtension: "MOV"){
            let secondAsset = AVAsset(url: url)
            //assets.append(secondAsset)
        }
        if let url = Bundle.main.url(forResource: "secondClip", withExtension: "MP4"){
            let secondAsset = AVAsset(url: url)
            //assets.append(secondAsset)
        }
        
        return assets

    }
    
    @objc func exportButtonPressed() -> Void {

        let composition = AVMutableComposition()
        let assets = loadAssetsToMerge()
        
        guard let asset = assets.first else{return}
        
        let tracksKey = #keyPath(AVAsset.tracks)
        asset.loadValuesAsynchronously(forKeys: [tracksKey]){
            DispatchQueue.main.async {
                let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                
                let path = documentDirectory.appendingPathComponent("exported.mp4").path
                let url = URL(fileURLWithPath: path)
                try? FileManager.default.removeItem(at: url)
                
                guard let videoTrack = asset.tracks(withMediaType: .video).first else {return}
                
                var canvasSize = videoTrack.naturalSize
                
                if self.selectedRatio.width > self.selectedRatio.height {
                    canvasSize.width = canvasSize.height * (self.selectedRatio.width / self.selectedRatio.height)

                }else{

                    canvasSize.height = canvasSize.width * (self.selectedRatio.height / self.selectedRatio.width)
                }
                
//                var layerSize = CGSize(width: canvasSize.width - 20, height: canvasSize.height - 20)

                //print("canvas \(canvasSize) layer \(layerSize)")
                guard let videoComposition = self.videoCompositionManager.getScaledVideoComposition(composition: composition, canvasSize: canvasSize, assets: assets,addBackground: true,aspectFit: self.fitButton.tag == 1 ? true : false) else {return}
                
//                let Y = (canvasSize.height - layerSize.height)/2
//                let X = (canvasSize.width - layerSize.width)/2
//                let layerOrigin = CGPoint(x: X, y: Y)
                
                
                if let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality){
                    
                    let duration = assets.reduce(CMTime.zero, {CMTimeAdd($0, $1.duration)})
                    
                    exporter.outputFileType = .mp4
                    exporter.timeRange = CMTimeRange(start: .zero, duration: duration)
                    exporter.videoComposition = videoComposition
                    exporter.outputURL = url
                    
                    exporter.exportAsynchronously {
                        switch exporter.status {
                        case .completed:
                            self.videoCompositionManager.exportToPhotoLibrary(url: exporter.outputURL!)
                            break
                        case .failed:
                            print(exporter.error?.localizedDescription ?? "Failed to video export")
                            break
                        default:
                            break
                        }
                        
                    }
                }
            }
        }
        
        
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
            
            playerLayer.frame = AVMakeRect(aspectRatio: videoCompositionManager.getAspectRatio(asset: asset), insideRect: rectangle)
            playerLayer.removeAllAnimations()
            
            
        }
        
        
    }
    
    func getResizedRectAsRatio(aspectRatio:CGSize,rect:CGRect) -> CGRect {
        
        let maxBounds = rect
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
        
        if selectedRatio != aspectRatioes.first {
            selectedRatio = aspectRatioes.first
            let rect = getResizedRectAsRatio(aspectRatio: selectedRatio,rect: self.videoView.superview!.bounds)
            resizeVideView(rect: rect)
            resizePlayerLayer(rect: rect)
            self.videoView.superview?.layoutIfNeeded()
        }
        self.ratioCollectionView.reloadData()
        
        
        slideShowTemplate.createVideo(allImages: loadImages(count: 4)) { [weak self] result in
            guard let self = self else {return}
            switch result {
            case .success(let url):
                self.fileUrl = url
                self.playVideo(url: url)
            case .failure(_): break
                
            }
        }
        //self.createVideo()
    }
    
    @IBAction func aspectFitButtonPressed(_ sender: Any?) {
        self.fitButton.backgroundColor = .lightGray
        self.fillButton.backgroundColor = .white
        self.fitButton.tag = fitButton.tag == 1 ? 0 : 1
        self.fillButton.tag = fillButton.tag == 1 ? 0 : 1

        playerLayer.videoGravity = .resizeAspect
        
        let rect = getResizedRectAsRatio(aspectRatio: selectedRatio,rect: self.videoView.superview!.bounds)
        
        self.resizeVideView(rect: rect)
        self.resizePlayerLayer(rect: rect)
        self.videoView.superview?.layoutIfNeeded()
        
        
    }
    
    @IBAction func aspectFillButtonPressed(_ sender: Any?) {
        
        self.fitButton.backgroundColor = .white
        self.fillButton.backgroundColor = .lightGray
        self.fillButton.tag = fillButton.tag == 1 ? 0 : 1
        self.fitButton.tag = fitButton.tag == 1 ? 0 : 1
        playerLayer.videoGravity = .resizeAspectFill
        
        let rect = getResizedRectAsRatio(aspectRatio: selectedRatio,rect: self.videoView.superview!.bounds)
        
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
        
        if selectedRatio == aspectRatioes[indexPath.row] {
            cell.backgroundColor = .lightGray
        }else{
            cell.backgroundColor = .white
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let cell = collectionView.cellForItem(at: indexPath) {
            
            for cell in collectionView.visibleCells{
                cell.backgroundColor = .white
            }
            
            cell.backgroundColor = .lightGray
            
            
        }
        
        selectedRatio = aspectRatioes[indexPath.item]
        playerLayer.videoGravity = .resizeAspect
        
        let rect = getResizedRectAsRatio(aspectRatio: selectedRatio,rect: self.videoView.superview!.bounds)
        
        self.resizeVideView(rect: rect)
        self.resizePlayerLayer(rect: rect)
        self.videoView.superview?.layoutIfNeeded()
        
    }
    
    
    
}
