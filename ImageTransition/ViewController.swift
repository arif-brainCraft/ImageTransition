//
//  ViewController.swift
//  ImageTransition
//
//  Created by BCL Device7 on 26/4/22.
//

import UIKit
import MTTransitions
import MetalPetal

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var mtiImageView: MTIImageView!

    private var sampleImages: [MTIImage] = []
    private var effects = MTTransition.Effect.allCases
    private var transitionIndex = 0
    var fromIndex = 0
    var toIndex = 1
    let duration:Double = 2.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSampleImages()
        doTransition()
    }
    
    func configureSampleImages() {
        for i in 0..<9 {
            if let imageUrl = Bundle.main.url(forResource: String(i), withExtension: "jpg") {
                if let image = MTIImage(contentsOf: imageUrl, options: [.SRGB:false]){
                    sampleImages.append(image.oriented(.downMirrored))
                }
                
            }
        }
    }
    
    func doTransition() -> Void {
        let effect = effects[transitionIndex].transition
        effect.duration = duration
        effect.transition(from: sampleImages[fromIndex], to: sampleImages[toIndex]) { image in
            self.mtiImageView.image = image
        } completion: { finished in
            self.doNextTransition()
        }

    }
    
    private func doNextTransition() {
        transitionIndex = (transitionIndex + 1) % effects.count
        fromIndex = toIndex
        var to = Int.random(in: 0..<sampleImages.count)
        while to == self.fromIndex {
            to = Int.random(in: 0..<sampleImages.count)
        }
        toIndex = to
        doTransition()
    }
}

