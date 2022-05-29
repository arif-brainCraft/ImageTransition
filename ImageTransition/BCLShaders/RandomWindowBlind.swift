//
//  RandomWindowBlind.swift
//  ImageTransition
//
//  Created by BCL Device7 on 24/5/22.
//

import Foundation
import MetalPetal
import simd

public class RandomWindowBlind: BCLTransition {
    public override init() {
        super.init()
        self.duration = 4.0;
    }
    public var startingAngle: Float = 90

    override var fragmentName: String {
        return "randomWindowBlindFragment"
    }

    override var parameters: [String: Any] {
        return [
            "startingAngle": startingAngle
        ]
    }
}
