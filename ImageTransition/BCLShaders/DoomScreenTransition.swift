//
//  MTBurnTransition.swift
//  MTTransitions
//
//  Created by alexiscn on 2019/1/28.
//

import MetalPetal

public class DoomScreenTransition: BCLTransition {
    public override init() {
        super.init()
        self.duration = 4.0;
    }
    public var startingAngle: Float = 90

    override var fragmentName: String {
        return "doomScreenTransitionFragment"
    }


}
