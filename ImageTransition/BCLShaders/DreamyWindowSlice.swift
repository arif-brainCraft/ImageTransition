//
//  DreamyWindowSlice.swift
//  ImageTransition
//
//  Created by BCL Device7 on 23/5/22.
//

import Foundation
import MTTransitions

public class DreamyWindowSlice: BCLTransition {
    
    public var startingAngle: Float = 90

    override var fragmentName: String {
        return "dreamyWindowSliceFragment"
    }

    override var parameters: [String: Any] {
        return [
            "startingAngle": startingAngle
        ]
    }
}
