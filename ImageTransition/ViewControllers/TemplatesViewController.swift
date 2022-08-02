//
//  TemplatesViewController.swift
//  ImageTransition
//
//  Created by BCL Device7 on 18/7/22.
//

import UIKit
import MetalPetal
import CoreMedia
import Photos

class TemplatesViewController: UIViewController {

    @IBOutlet var slideShowView:MTIImageView!
    
    var displayLink: CADisplayLink!
    var templates:[Template] = Templates.featured
    var slideShowTemplate:SlideShowTemplate?
    var lastFrameTime:Float = 0
    var mtiView:MTIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Slide Show Maker"
        
        let exportButton = UIBarButtonItem(title: "Export", style: .done, target: self, action: #selector(exportTemplate(_:)))
        
        self.navigationItem.rightBarButtonItem = exportButton
        
        slideShowTemplate = templates.first?.getInstance(allImageUrls: loadImageUrls(count: 3))
        slideShowTemplate?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkHandler))
        displayLink.add(to: .current, forMode: .common)
        if #available(iOS 15.0, *) {
            displayLink.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 40, __preferred: 30)
        } else {
            displayLink.preferredFramesPerSecond = 40
        }

    }
    
    func showSelectedTemplate() -> Void {
        
        DispatchQueue.global().async {
            self.slideShowTemplate?.start( forExport: false, completion:{ result in
                switch result {
                case .success(_):
                   // self.showSelectedTemplate()
                    break
                    
                case .failure(_): break

                case .none:
                    break
                }
            })
        }

    }
    
    @objc func displayLinkHandler() -> Void{
        
        let actualFramesPerSecond = 1 / (displayLink.targetTimestamp - displayLink.timestamp)
        
        let userInfo = ["actualFramesPerSecond" : actualFramesPerSecond]
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "DisplayLinkHandler"), object: nil, userInfo: userInfo)
 
        slideShowTemplate?.increaseDisplayCount()
        let progress = slideShowTemplate?.getProgress() ?? 0.0
        autoreleasepool {
            if let frame = slideShowTemplate?.getFrame(progress:progress ){
                self.showImage(image: frame)
            }
        }

        if progress >= 1.0 {
            slideShowTemplate?.reset()
        }
    }
    
    func loadImageUrls(count:Int) -> [URL] {
        var images = [URL]()
        for _ in 0..<count {
            let i = Int.random(in: 0..<9)
            if let url = Bundle.main.url(forResource: String(i), withExtension: "jpg") {
                images.append(url)
            }
        }
        return images
    }
    
    @objc func exportTemplate(_ sender:Any) -> Void {
        self.slideShowTemplate?.start(forExport: true, completion: { result in
            switch result {
            case .success(let url):
                if let outputUrl = url {
                    self.exportToPhotoLibrary(url: outputUrl)
                }
                break
                
            case .failure(_): break

            case .none:
                break
            }
        })
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
                        
                        var msg = "Can't Save The Video."
                        if success && error == nil {
                            msg = "Video Saved To Camera Roll"
                        }
                        
                        let alert = UIAlertController(title: msg, message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                            
                        }))
                        print("Video Saved To Camera Roll")
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                
                break;
            default:
                print("PhotoLibrary not authorized")
                
                break;
            }
        }
    }
}


extension TemplatesViewController:SlideShowTemplateDelegate{
    func update(progress: Float) {
        
    }
    
    func showImage(image: MTIImage) {
        DispatchQueue.main.async {
            autoreleasepool {
               // self.slideShowView.image = nil
                self.slideShowView.image = image
            }
        }

    }
    
    
}

extension TemplatesViewController:UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = collectionView.frame.width / 2  - 5

        return CGSize(width: width, height: width + 20 )
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat(10)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return templates.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let tempCell = cell as? TemplateCollectionViewCell  {
            tempCell.addDisplayLink()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let tempCell = cell as? TemplateCollectionViewCell  {
            tempCell.removeDisplayLink()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TemplateCollectionViewCell", for: indexPath) as! TemplateCollectionViewCell
        cell.nameLabel.text = self.templates[indexPath.row].name
        cell.backgroundColor = .lightGray
        
        cell.slideShowTemplate = templates[indexPath.row].getInstance(allImageUrls: loadImageUrls(count: 3))
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.slideShowTemplate = templates[indexPath.row].getInstance(allImageUrls: loadImageUrls(count: 5))
    }
    
    
}


