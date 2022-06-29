//
//  GradualBoxBrush.swift
//  ImageTransition
//
//  Created by BCL Device7 on 28/6/22.
//

import Foundation
import MetalPetal
import simd

public class GradualBoxBrush: BCLTransition {
    
    public override init() {
        super.init()
        self.duration = 3.0;
        self.parameters = ["direction":simd_float2(x: 0.0, y: 1.0)]
    }

    override var fragmentName: String {
        return "gradualBoxBrushFragment"
    }


}
