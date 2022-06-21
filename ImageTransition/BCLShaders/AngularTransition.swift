//
//  DreamyWindowSlice.swift
//  ImageTransition
//
//  Created by BCL Device7 on 23/5/22.
//

import Foundation
import MTTransitions

public class AngularTransition: BCLTransition {
    public override init() {
        super.init()
        self.duration = 3.0;
        self.parameters = ["startingAngle": startingAngle]
    }
    public var startingAngle: Float = 90

    override var fragmentName: String {
        return "AngularFragment"
    }


}
