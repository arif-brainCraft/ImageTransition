//
//  ShakyZoom.swift
//  ImageTransition
//
//  Created by BCL Device7 on 31/8/22.
//

import Foundation
import MTTransitions

public class ShakyZoom: BCLTransition {
    
    public var zoom_quickness: Float = 1.0
    public var rotation: Float = 0.0

    public override init() {
        super.init()
        self.duration = 2.0;
        self.parameters = ["zoom_quickness": zoom_quickness,
                           "rotation": rotation]
    }

    override var fragmentName: String {
        return "shakyZoom"
    }

}
