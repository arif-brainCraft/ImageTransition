//
//  TextureOverlayWithTranslationFilter.swift
//  ImageTransition
//
//  Created by BCL Device7 on 24/8/22.
//

import Foundation

public class TextureOverlayWithTranslationFilter: BCLTransition {



    var opacityMul = 0.25{
        didSet{
            setParams()
        }
    }
    
    var frameRatio = 1.0{
        didSet{
            setParams()
        }
    }

    func setParams() -> Void {
        self.parameters = ["opacityMul":opacityMul,
                           "frameRatio":frameRatio
        ]
    }
    
    override var fragmentName: String {
        return "textureOvelayWithTransition"
    }
    
}
