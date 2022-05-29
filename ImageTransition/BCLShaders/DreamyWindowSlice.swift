//
//  DreamyWindowSlice.swift
//  ImageTransition
//
//  Created by BCL Device7 on 23/5/22.
//

import Foundation
import MTTransitions

public class DreamyWindowSlice: BCLTransition {
    public override init() {
        super.init()
        self.duration = 3.0;
    }
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
