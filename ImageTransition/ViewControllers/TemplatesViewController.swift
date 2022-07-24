//
//  TemplatesViewController.swift
//  ImageTransition
//
//  Created by BCL Device7 on 18/7/22.
//

import UIKit
import MetalPetal

class TemplatesViewController: UIViewController {

    @IBOutlet var slideShowView:MTIImageView!
    
    var displayLink: CADisplayLink!
    var templates:[[Template]] = Templates.twoD(array: Templates.featured, by: 2)
    var slideShowTemplate:GradualBoxTemplate!

    var mtiView:MTIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Slide Show Maker"
        slideShowTemplate = GradualBoxTemplate(allImageUrls: self.loadImageUrls(count: 5), forExport: false)
        slideShowTemplate.delegate = self
        
        
//        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkHandler))
//        displayLink.add(to: .current, forMode: .default)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showSelectedTemplate()

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
        //print("actualFramesPerSecond \(displayLink.timestamp)")
        

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
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TemplateCollectionViewCell", for: indexPath) as! TemplateCollectionViewCell
        cell.nameLabel.text = self.templates[indexPath.section][indexPath.row].name
        cell.backgroundColor = .lightGray
       // cell.localThread = DispatchQueue(label:"templateThread\(indexPath.section)\(indexPath.row)")
        cell.slideShowTemplate = GradualBoxTemplate(allImageUrls: loadImageUrls(count: 3), forExport: false)
        cell.imageUrls = loadImageUrls(count: 5)
        //cell.showSelectedTemplate()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    
}


