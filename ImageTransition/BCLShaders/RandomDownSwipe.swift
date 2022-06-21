//
//  MTBurnTransition.swift
//  MTTransitions
//
//  Created by alexiscn on 2019/1/28.
//

import MetalPetal

public class RandomDownSwipe: BCLTransition {
    public override init() {
        super.init()
        self.duration = 4.0;
        self.parameters = ["startingAngle": startingAngle]
    }
    public var startingAngle: Float = 90

    override var fragmentName: String {
        return "randomDownSwipeFragment"
    }

}
