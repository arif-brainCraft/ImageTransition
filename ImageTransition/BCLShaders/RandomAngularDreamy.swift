//
//  MTBurnTransition.swift
//  MTTransitions
//
//  Created by alexiscn on 2019/1/28.
//

import MetalPetal

public class RandomAngularDreamy: BCLTransition {
    
    public var startingAngle: Float = 90

    override var fragmentName: String {
        return "randomAngularDreamyFragment"
    }

    override var parameters: [String: Any] {
        return [
            "startingAngle": startingAngle
        ]
    }
}
