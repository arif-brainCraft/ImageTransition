//
//  MTBurnTransition.swift
//  MTTransitions
//
//  Created by alexiscn on 2019/1/28.
//

import MetalPetal

public class RandomDownSwipe: BCLTransition {
    
    public var startingAngle: Float = 90

    override var fragmentName: String {
        return "randomDownSwipeFragment"
    }

    override var parameters: [String: Any] {
        return [
            "startingAngle": startingAngle
        ]
    }
}
