//
//  DreamyWindowSlice.swift
//  ImageTransition
//
//  Created by BCL Device7 on 23/5/22.
//

import Foundation
import MTTransitions

public class AngularTransition: BCLTransition {
    
    public var startingAngle: Float = 90

    override var fragmentName: String {
        return "AngularFragment"
    }

    override var parameters: [String: Any] {
        return [
            "startingAngle": startingAngle
        ]
    }
}
