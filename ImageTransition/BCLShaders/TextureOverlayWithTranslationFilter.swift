//
//  TextureOverlayWithTranslationFilter.swift
//  ImageTransition
//
//  Created by BCL Device7 on 24/8/22.
//

import Foundation

public class TextureOverlayWithTranslationFilter: BCLTransition {
    let HEARTS_OVERLAY = 0
    let DOTS_OVERLAY = 1

    private var overlayTexName = "";

    var opacityMul = 0.25{
        didSet{
            setParams()
        }
    }
    var overlayId = 1{
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
    
    init(overlayId:Int) {
        super.init()
        self.overlayId = overlayId
        
        switch (self.overlayId){
        case HEARTS_OVERLAY:
            overlayTexName = ""
            break
        case DOTS_OVERLAY:
            overlayTexName = ""
            break
        default:
            break
        }
        
        self.duration = 3.0;
        setParams()
    }
    
    override var fragmentName: String {
        return "textureOvelayWithTransition"
    }
    
}
