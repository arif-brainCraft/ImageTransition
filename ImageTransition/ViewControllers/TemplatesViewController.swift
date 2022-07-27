//
//  TemplatesViewController.swift
//  ImageTransition
//
//  Created by BCL Device7 on 18/7/22.
//

import UIKit
import MetalPetal
import CoreMedia

class TemplatesViewController: UIViewController {

    @IBOutlet var slideShowView:MTIImageView!
    
    var displayLink: CADisplayLink!
    var templates:[[Template]] = Templates.twoD(array: Templates.featured, by: 2)
    var slideShowTemplate:GradualBoxTemplate!
    var lastFrameTime:Float = 0
    var mtiView:MTIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Slide Show Maker"
        slideShowTemplate = GradualBoxTemplate(allImageUrls: self.loadImageUrls(count: 5), forExport: false)
        slideShowTemplate.delegate = self
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
            self.slideShowTemplate.start( completion:{ result in
                switch result {
                case .success(let url):
                   // self.showSelectedTemplate()
                    break
                    
                case .failure(_): break

                case .none:
                    break
                }
            })
        }

    }
    
    @objc func displayLinkHandler(){
        
        let actualFramesPerSecond = 1 / (displayLink.targetTimestamp - displayLink.timestamp)
        
        let userInfo = ["actualFramesPerSecond" : actualFramesPerSecond]
        print("actualFramesPerSecond \(actualFramesPerSecond)")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "DisplayLinkHandler"), object: nil, userInfo: userInfo)

        slideShowTemplate.increaseDisplayCount()
        let progress = slideShowTemplate.getProgress()
        autoreleasepool {
            if let frame = slideShowTemplate.getFrame(progress:progress ){
                self.showImage(image: frame)
            }
        }

        if progress >= 1.0 {
            slideShowTemplate.reset()
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
        
        let width = collectionView.frame.width / 2 - 5 * 2
        
        return CGSize(width: width, height: width + 20)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return templates.count
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return templates[section].count
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
        cell.nameLabel.text = self.templates[indexPath.section][indexPath.row].name
        cell.backgroundColor = .lightGray
        
        if self.templates[indexPath.section][indexPath.row].className == SquareBoxPopTemplate.self{
            cell.slideShowTemplate = SquareBoxPopTemplate(allImageUrls: loadImageUrls(count: 3), forExport: false)

        }else{
            cell.slideShowTemplate = GradualBoxTemplate(allImageUrls: loadImageUrls(count: 3), forExport: false)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    
}


