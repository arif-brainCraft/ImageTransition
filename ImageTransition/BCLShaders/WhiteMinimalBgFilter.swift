//
//  WhiteMinimalBgFilter.swift
//  ImageTransition
//
//  Created by BCL Device7 on 14/6/22.
//

import Foundation
import MetalPetal

public class WhiteMinimalBgFilter: BCLTransition {
    public override init() {
        super.init()
        self.duration = 3.0;
    }

    override var fragmentName: String {
        return "whiteMinimalBgFilterFragment"
    }


}
